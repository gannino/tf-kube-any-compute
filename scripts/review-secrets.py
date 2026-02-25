#!/usr/bin/env python3
"""
Security Report Review Tool

Analyzes security scan results and the secrets baseline to help identify
potential actual secrets vs false positives in documentation.

Usage:
    python scripts/review-secrets.py [--baseline] [--checkov] [--trivy] [--tfsec] [--all] [--show-findings] [--limit N]

Examples:
    python scripts/review-secrets.py --all                    # Review all reports
    python scripts/review-secrets.py --baseline               # Only review secrets baseline
    python scripts/review-secrets.py --baseline --show-findings  # Show actual findings
    python scripts/review-secrets.py --baseline --show-findings --limit 20  # Show first 20 findings
    python scripts/review-secrets.py --checkov                # Only review Checkov results
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
from collections import defaultdict


class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'      # Critical/High severity
    YELLOW = '\033[93m'   # Warning/Medium severity
    GREEN = '\033[92m'    # Safe/Low severity
    BLUE = '\033[94m'     # Info
    MAGENTA = '\033[95m'  # Headers
    CYAN = '\033[96m'     # File paths
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    RESET = '\033[0m'
    DIM = '\033[2m'


def print_header(text: str):
    """Print a formatted header"""
    print(f"\n{Colors.MAGENTA}{Colors.BOLD}{'=' * 80}{Colors.RESET}")
    print(f"{Colors.MAGENTA}{Colors.BOLD}{text:^80}{Colors.RESET}")
    print(f"{Colors.MAGENTA}{Colors.BOLD}{'=' * 80}{Colors.RESET}\n")


def print_subheader(text: str):
    """Print a formatted subheader"""
    print(f"\n{Colors.CYAN}{Colors.BOLD}{text}{Colors.RESET}")
    print(f"{Colors.CYAN}{'-' * len(text)}{Colors.RESET}\n")


def color_severity(severity: str) -> str:
    """Add color to severity labels"""
    severity = severity.upper()
    if severity in ['CRITICAL', 'HIGH', 'ERROR']:
        return f"{Colors.RED}{severity}{Colors.RESET}"
    elif severity in ['MEDIUM', 'WARNING']:
        return f"{Colors.YELLOW}{severity}{Colors.RESET}"
    elif severity in ['LOW', 'NOTE']:
        return f"{Colors.GREEN}{severity}{Colors.RESET}"
    return severity


def is_likely_secret(value: str, context: str = "") -> bool:
    """
    Heuristic check if a value is likely an actual secret vs documentation/example.

    Returns True if the value looks like a real secret.
    """
    # Skip obvious examples/placeholders
    examples = [
        'changeme', 'change-me', 'change_me', 'example', 'your-', 'your.',
        'placeholder', 'test-', 'demo-', 'dummy', 'fake', 'xxx',
        '<secret>', '<password>', '<token>', '<key>',
        'secret-change-me', 'change-this',
        'headlamp-secret-change-me', 'changeme-headlamp',
        'your-email@example.com', 'your-api-key', 'your-password',
        'your-token', 'your-secret', 'your-username',
    ]

    value_lower = value.lower()
    if any(example in value_lower for example in examples):
        return False

    # Check if it's too short to be a real secret
    if len(value) < 16:
        return False

    # Check if it's a Kubernetes service account path (legitimate)
    if '/var/run/secrets/kubernetes.io/serviceaccount/' in value:
        return False

    # Check if it's a variable name or path
    if any(char in value for char in ['/', '\\', '{', '}', '$', '.', '_', '=']):
        return False

    # Check if it looks like a real secret
    # - Long enough
    # - Contains mix of alphanumeric and special chars
    # - Not a common word
    if len(value) >= 16:
        has_alpha = any(c.isalpha() for c in value)
        has_digit = any(c.isdigit() for c in value)
        has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in value)

        if has_alpha and has_digit:
            return True

    return False


def save_findings_to_file(baseline_path: Path, output_path: Path, limit: int = 10, show_all: bool = False):
    """
    Save detailed findings to a readable text file.

    Args:
        baseline_path: Path to the .secrets.baseline file
        output_path: Path to save the report
        limit: Maximum number of findings to show per file
        show_all: If True, show all findings (ignores limit)
    """
    if not baseline_path.exists():
        return False

    with open(baseline_path, 'r') as f:
        baseline = json.load(f)

    results = baseline.get('results', {})

    if not results:
        return False

    # Group findings by file
    findings_by_file = {}
    for filename, secrets in results.items():
        if not secrets:
            continue
        secret_list = secrets if isinstance(secrets, list) else [secrets]
        findings_by_file[filename] = secret_list

    # Sort files by number of findings
    sorted_files = sorted(findings_by_file.items(), key=lambda x: -len(x[1]))

    with open(output_path, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("SECURITY BASELINE DETAILED FINDINGS REPORT\n")
        f.write("=" * 80 + "\n\n")

        f.write(f"Baseline File: {baseline_path}\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Total Files with Findings: {len(sorted_files)}\n")
        f.write(f"Total Findings: {sum(len(s) for s in findings_by_file.values())}\n\n")

        for idx, (filename, secrets) in enumerate(sorted_files, 1):
            f.write("=" * 80 + "\n")
            f.write(f"[{idx}/{len(sorted_files)}] {filename}\n")
            f.write("=" * 80 + "\n")

            # Determine file type
            is_safe = any(safe in filename for safe in ['.example', 'test-', 'README.md', '.md'])
            if is_safe:
                f.write("Type: Documentation/Example file (typically safe)\n")
            else:
                f.write("Type: Code file (review recommended)\n")

            f.write(f"\nFindings ({len(secrets)} total):\n\n")

            # Show limited or all findings
            secrets_to_show = secrets if show_all else secrets[:limit]

            for secret_idx, secret in enumerate(secrets_to_show, 1):
                f.write(f"  [{secret_idx}] ")

                if isinstance(secret, dict):
                    secret_type = secret.get('type', 'Unknown')
                    f.write(f"Type: {secret_type}\n")

                    if 'hashed_secret' in secret:
                        hash_preview = secret['hashed_secret'][:40]
                        f.write(f"       Hash: {hash_preview}...\n")
                else:
                    secret_str = str(secret)
                    if len(secret_str) > 80:
                        secret_str = secret_str[:77] + "..."
                    f.write(f"{secret_str}\n")

                # Try to find line context
                file_path = Path(filename)
                if file_path.exists():
                    try:
                        with open(file_path, 'r') as source_file:
                            for line_num, line in enumerate(source_file, 1):
                                if any(word in line.lower() for word in ['secret', 'password', 'token', 'key', 'credential']):
                                    f.write(f"       Line {line_num}: {line.strip()[:100]}\n")
                                    break
                    except Exception:
                        f.write("       (Could not read file context)\n")

                f.write("\n")

            if not show_all and len(secrets) > limit:
                f.write(f"  ... and {len(secrets) - limit} more findings in this file\n")
                f.write(f"  Use --show-all to see all findings\n\n")

            f.write("\n")

        f.write("=" * 80 + "\n")
        f.write("END OF REPORT\n")
        f.write("=" * 80 + "\n")

    return True


def show_baseline_findings(baseline_path: Path, limit: int = 10, show_all: bool = False, save_to_file: Optional[Path] = None):
    """
    Show detailed findings from the baseline with file context.

    Args:
        baseline_path: Path to the .secrets.baseline file
        limit: Maximum number of findings to show per file
        show_all: If True, show all findings (ignores limit)
        save_to_file: Path to save report to (optional)
    """
    print_subheader("DETAILED FINDINGS REVIEW")

    if not baseline_path.exists():
        print(f"{Colors.RED}Error: Baseline file not found: {baseline_path}{Colors.RESET}")
        return

    with open(baseline_path, 'r') as f:
        baseline = json.load(f)

    results = baseline.get('results', {})

    if not results:
        print(f"{Colors.YELLOW}No findings in baseline{Colors.RESET}")
        return

    # Group findings by file and show top ones
    findings_by_file = {}
    for filename, secrets in results.items():
        if not secrets:
            continue

        secret_list = secrets if isinstance(secrets, list) else [secrets]
        findings_by_file[filename] = secret_list

    # Sort files by number of findings (most first)
    sorted_files = sorted(findings_by_file.items(), key=lambda x: -len(x[1]))

    # Save to file if requested
    if save_to_file:
        print(f"{Colors.BLUE}Saving findings to: {save_to_file}{Colors.RESET}")
        if save_findings_to_file(baseline_path, save_to_file, limit=limit, show_all=show_all):
            print(f"{Colors.GREEN}✅ Report saved successfully{Colors.RESET}\n")
        else:
            print(f"{Colors.RED}❌ Failed to save report{Colors.RESET}\n")

    print(f"{Colors.BLUE}Showing findings from {len(sorted_files)} files{Colors.RESET}")
    if not show_all:
        print(f"{Colors.RESET}Showing first {limit} findings per file (use --show-all to see all){Colors.RESET}")
    print()

    for idx, (filename, secrets) in enumerate(sorted_files, 1):
        print(f"{Colors.CYAN}{Colors.BOLD}{'='*80}{Colors.RESET}")
        print(f"{Colors.CYAN}{Colors.BOLD}[{idx}/{len(sorted_files)}] {filename}{Colors.RESET}")
        print(f"{Colors.CYAN}{Colors.BOLD}{'='*80}{Colors.RESET}")

        # Determine if this is a safe file
        is_safe = any(safe in filename for safe in ['.example', 'test-', 'README.md', '.md'])
        if is_safe:
            print(f"  {Colors.GREEN}Type: Documentation/Example file (typically safe){Colors.RESET}")
        else:
            print(f"  {Colors.YELLOW}Type: Code file (review recommended){Colors.RESET}")

        # Check if file exists
        file_path = Path(filename)
        if file_path.exists():
            print(f"  {Colors.RESET}File exists and is readable{Colors.RESET}")
        else:
            print(f"  {Colors.YELLOW}File not found (may have been moved/deleted){Colors.RESET}")

        print(f"\n  {Colors.BLUE}Findings ({len(secrets)} total):{Colors.RESET}\n")

        # Pre-read the file to get line numbers for secrets
        file_lines = []
        secret_lines = {}  # Map line numbers to secret keywords found
        if file_path.exists():
            try:
                with open(file_path, 'r') as f:
                    file_lines = [(i+1, line.rstrip()) for i, line in enumerate(f)]

                    # Find all lines with secret-related keywords
                    for line_num, line in file_lines:
                        if any(word in line.lower() for word in ['secret', 'password', 'token', 'key', 'credential']):
                            secret_lines[line_num] = line
            except Exception as e:
                print(f"  {Colors.YELLOW}Warning: Could not read file: {e}{Colors.RESET}\n")

        # Get a list of line numbers to use (in order)
        available_line_nums = list(secret_lines.keys())
        current_line_idx = 0

        # Show limited or all findings
        secrets_to_show = secrets if show_all else secrets[:limit]

        for secret_idx, secret in enumerate(secrets_to_show, 1):
            # Handle different secret formats in baseline
            if isinstance(secret, dict):
                # detect-secrets format: has type, hashed_secret, filename
                secret_type = secret.get('type', 'Unknown')

                print(f"    {Colors.BLUE}[{secret_idx}] {Colors.BOLD}Type: {secret_type}{Colors.RESET}")

                # Show additional metadata
                if 'hashed_secret' in secret:
                    hash_preview = secret['hashed_secret'][:40]
                    print(f"         {Colors.RESET}Hash: {hash_preview}...{Colors.RESET}")

                # Try to find line number if file exists and we have lines
                if available_line_nums and current_line_idx < len(available_line_nums):
                    line_num = available_line_nums[current_line_idx]
                    line = secret_lines[line_num]
                    print(f"         {Colors.RESET}Line {line_num}:{Colors.RESET}")
                    if len(line) > 100:
                        line = line[:97] + "..."
                    print(f"         {Colors.RESET}    {line}{Colors.RESET}")
                    current_line_idx += 1
                elif file_lines:
                    print(f"         {Colors.RESET}(No more matching lines found){Colors.RESET}")
            else:
                # Simple string format
                secret_str = str(secret)

                # Truncate if too long
                display_secret = secret_str
                if len(display_secret) > 80:
                    display_secret = display_secret[:77] + "..."

                # Check if it looks suspicious
                is_suspicious = is_likely_secret(secret_str, filename)

                if is_suspicious:
                    print(f"    {Colors.RED}[{secret_idx}] {Colors.BOLD}{display_secret}{Colors.RESET}")
                    print(f"         {Colors.RED}⚠️  POSSIBLE REAL SECRET - REVIEW REQUIRED{Colors.RESET}")
                else:
                    print(f"    {Colors.GREEN}[{secret_idx}] {display_secret}{Colors.RESET}")

                # Try to find line number if file exists and we have lines
                if file_lines:
                    found = False
                    for line_num, line in file_lines:
                        if secret_str in line:
                            # Show context around the finding
                            print(f"         {Colors.RESET}Line {line_num}:{Colors.RESET}")

                            # Show the actual line
                            display_line = line
                            if len(display_line) > 100:
                                display_line = display_line[:97] + "..."
                            print(f"         {Colors.RESET}    {display_line}{Colors.RESET}")

                            # Highlight the secret in the line
                            if secret_str in display_line:
                                highlighted = display_line.replace(
                                    secret_str,
                                    f"{Colors.YELLOW}{secret_str}{Colors.RESET}"
                                )
                                print(f"         {Colors.RESET}    ↑ {highlighted}{Colors.RESET}")
                            found = True
                            break

                    if not found:
                        print(f"         {Colors.RESET}(Could not find exact line in file){Colors.RESET}")

            print()

        if not show_all and len(secrets) > limit:
            print(f"  {Colors.RESET}... and {len(secrets) - limit} more findings in this file{Colors.RESET}")
            print(f"  {Colors.RESET}Use --show-all to see all findings{Colors.RESET}")

        print()

    print(f"{Colors.BLUE}Review Complete: {len(sorted_files)} files with findings{Colors.RESET}")
    print(f"{Colors.RESET}Total findings: {sum(len(s) for s in findings_by_file.values())}{Colors.RESET}")


def analyze_baseline(baseline_path: Path, show_findings: bool = False, findings_limit: int = 10, show_all: bool = False, save_to_file: Optional[Path] = None) -> Dict[str, Any]:
    """Analyze the detect-secrets baseline file"""
    print_header("SECRET BASELINE ANALYSIS")

    if not baseline_path.exists():
        print(f"{Colors.RED}Error: Baseline file not found: {baseline_path}{Colors.RESET}")
        return {}

    with open(baseline_path, 'r') as f:
        baseline = json.load(f)

    results = baseline.get('results', {})
    excluded_files = baseline.get('exclude_files', [])

    total_findings = sum(len(v) if isinstance(v, list) else 1 for v in results.values())

    print(f"{Colors.BLUE}Baseline File:{Colors.RESET} {baseline_path}")
    print(f"{Colors.BLUE}Version:{Colors.RESET} {baseline.get('version', 'unknown')}")
    print(f"{Colors.BLUE}Generated:{Colors.RESET} {baseline.get('generated_at', 'unknown')}")
    print(f"{Colors.BLUE}Total Findings:{Colors.RESET} {total_findings}")
    print(f"{Colors.BLUE}Excluded Patterns:{Colors.RESET} {len(excluded_files)}")

    # Analyze findings by file type
    findings_by_type = defaultdict(int)
    findings_by_file = defaultdict(list)
    suspicious = []

    for filename, secrets in results.items():
        if not secrets:
            continue

        ext = Path(filename).suffix
        findings_by_type[ext] += len(secrets) if isinstance(secrets, list) else 1

        for secret in (secrets if isinstance(secrets, list) else [secrets]):
            secret_str = str(secret)
            findings_by_file[filename].append(secret_str)

            # Check if this might be a real secret
            if is_likely_secret(secret_str, filename):
                suspicious.append({
                    'file': filename,
                    'secret': secret_str,
                    'reason': 'Heuristic check suggests this might be a real secret'
                })

    print_subheader("Findings by File Type")
    for ext, count in sorted(findings_by_type.items(), key=lambda x: -x[1]):
        print(f"  {Colors.CYAN}{ext if ext else '(no ext)'}{Colors.RESET}: {count} findings")

    print_subheader("Top 10 Files with Most Findings")
    sorted_files = sorted(findings_by_file.items(), key=lambda x: -len(x[1]))
    for filename, secrets in sorted_files[:10]:
        ext = Path(filename).suffix
        print(f"  {Colors.CYAN}{filename}{Colors.RESET} ({ext}): {len(secrets)} findings")

    if suspicious:
        print_subheader(f"{Colors.RED}{Colors.BOLD}POTENTIALLY REAL SECRETS DETECTED{Colors.RESET}")
        print(f"{Colors.YELLOW}The following findings may be actual secrets that need review:{Colors.RESET}\n")
        for item in suspicious:
            print(f"  {Colors.RED}File:{Colors.RESET} {Colors.CYAN}{item['file']}{Colors.RESET}")
            print(f"  {Colors.RED}Secret:{Colors.RESET} {item['secret'][:60]}{'...' if len(item['secret']) > 60 else ''}")
            print(f"  {Colors.RED}Reason:{Colors.RESET} {item['reason']}\n")
    else:
        print_subheader(f"{Colors.GREEN}{Colors.BOLD}SUSPICIOUS FINDINGS CHECK{Colors.RESET}")
        print(f"{Colors.GREEN}No obvious real secrets detected (all appear to be examples/docs){Colors.RESET}")

    # Verify exclusions are working
    print_subheader("Exclusion Verification")
    dangerous_patterns = ['.tfvars', '.backup', 'terraform.tfstate.d']
    safe_patterns = ['.example', 'test-']  # These are intentional test/example files
    found_dangerous = []

    for filename in findings_by_file.keys():
        for pattern in dangerous_patterns:
            if pattern in filename:
                # But exclude if it's a known safe pattern
                if not any(safe in filename for safe in safe_patterns):
                    found_dangerous.append(filename)
                break

    if found_dangerous:
        print(f"{Colors.RED}WARNING: Found entries from potentially dangerous files:{Colors.RESET}")
        for f in found_dangerous:
            print(f"  {Colors.RED}  - {f}{Colors.RESET}")
    else:
        print(f"{Colors.GREEN}No entries from .tfvars, .backup, or terraform.tfstate.d files{Colors.RESET}")
        print(f"{Colors.RESET}(excluding .example and test- files which are safe){Colors.RESET}")

    # Show detailed findings if requested
    if show_findings:
        print()  # Add spacing
        show_baseline_findings(baseline_path, limit=findings_limit, show_all=show_all, save_to_file=save_to_file)

    return {
        'total_findings': total_findings,
        'findings_by_type': dict(findings_by_type),
        'suspicious_count': len(suspicious),
        'suspicious': suspicious,
        'dangerous_files': found_dangerous
    }


def analyze_checkov(report_path: Optional[Path]) -> Dict[str, Any]:
    """Analyze Checkov SARIF report"""
    print_header("CHECKOV SECURITY ANALYSIS")

    if not report_path or not report_path.exists():
        print(f"{Colors.YELLOW}No Checkov report found{Colors.RESET}")
        return {}

    with open(report_path, 'r') as f:
        sarif = json.load(f)

    runs = sarif.get('runs', [])
    if not runs:
        print(f"{Colors.YELLOW}No Checkov runs found in report{Colors.RESET}")
        return {}

    results = runs[0].get('results', [])

    # Analyze by severity
    by_severity = defaultdict(int)
    by_rule = defaultdict(list)
    secret_related = []

    for result in results:
        level = result.get('level', 'unknown')
        rule_id = result.get('ruleId', 'unknown')
        message = result.get('message', {}).get('text', '')

        by_severity[level] += 1
        by_rule[rule_id].append(result.get('locations', []))

        # Check if this is secret-related
        if any(word in rule_id.lower() for word in ['secret', 'credential', 'password', 'token', 'key']):
            secret_related.append({
                'rule': rule_id,
                'level': level,
                'message': message
            })

    print(f"{Colors.BLUE}Total Findings:{Colors.RESET} {len(results)}")
    print(f"{Colors.BLUE}Rules Triggered:{Colors.RESET} {len(by_rule)}")

    print_subheader("Findings by Severity")
    for severity in ['error', 'warning', 'note']:
        count = by_severity.get(severity, 0)
        if count > 0:
            colored_sev = color_severity(severity)
            print(f"  {colored_sev}: {count}")

    if secret_related:
        print_subheader(f"{Colors.YELLOW}SECRET-RELATED FINDINGS{Colors.RESET}")
        for item in secret_related:
            colored_sev = color_severity(item['level'])
            print(f"  {colored_sev} {item['rule']}: {item['message'][:80]}")
    else:
        print_subheader(f"{Colors.GREEN}SECRET-RELATED CHECKS{Colors.RESET}")
        print(f"{Colors.GREEN}No findings related to secrets/credentials/tokens/keys{Colors.RESET}")

    print_subheader("Top 10 Most Common Issues")
    sorted_rules = sorted(by_rule.items(), key=lambda x: -len(x[1]))
    for rule, locations in sorted_rules[:10]:
        print(f"  {Colors.CYAN}{rule}{Colors.RESET}: {len(locations)} occurrences")

    return {
        'total_findings': len(results),
        'by_severity': dict(by_severity),
        'secret_related_count': len(secret_related),
        'secret_related': secret_related
    }


def analyze_tfsec(report_path: Optional[Path]) -> Dict[str, Any]:
    """Analyze tfsec JSON report"""
    print_header("TFSEC SECURITY ANALYSIS")

    if not report_path or not report_path.exists():
        print(f"{Colors.YELLOW}No tfsec report found{Colors.RESET}")
        return {}

    with open(report_path, 'r') as f:
        report = json.load(f)

    results = report.get('results', [])

    # Analyze by severity
    by_severity = defaultdict(int)
    by_rule_id = defaultdict(list)

    for result in results:
        severity = result.get('severity', 'unknown')
        rule_id = result.get('rule_id', 'unknown')

        by_severity[severity] += 1
        by_rule_id[rule_id].append(result.get('location', {}).get('filename', ''))

    print(f"{Colors.BLUE}Total Findings:{Colors.RESET} {len(results)}")

    print_subheader("Findings by Severity")
    for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
        count = by_severity.get(severity, 0)
        if count > 0:
            colored_sev = color_severity(severity)
            print(f"  {colored_sev}: {count}")

    if not results:
        print(f"{Colors.GREEN}{Colors.BOLD}NO SECURITY ISSUES FOUND{Colors.RESET}")

    return {
        'total_findings': len(results),
        'by_severity': dict(by_severity)
    }


def analyze_trivy(report_path: Optional[Path]) -> Dict[str, Any]:
    """Analyze Trivy JSON report"""
    print_header("TRIVY SECURITY ANALYSIS")

    if not report_path or not report_path.exists():
        print(f"{Colors.YELLOW}No Trivy report found{Colors.RESET}")
        return {}

    with open(report_path, 'r') as f:
        report = json.load(f)

    results = report.get('Results', [])

    total_vulnerabilities = 0
    by_severity = defaultdict(int)

    for result in results:
        vulnerabilities = result.get('Vulnerabilities', [])
        if vulnerabilities is None:
            continue

        for vuln in vulnerabilities:
            severity = vuln.get('Severity', 'UNKNOWN')
            by_severity[severity] += 1
            total_vulnerabilities += 1

    print(f"{Colors.BLUE}Total Vulnerabilities:{Colors.RESET} {total_vulnerabilities}")

    print_subheader("Vulnerabilities by Severity")
    for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
        count = by_severity.get(severity, 0)
        if count > 0:
            colored_sev = color_severity(severity)
            print(f"  {colored_sev}: {count}")

    if total_vulnerabilities == 0:
        print(f"{Colors.GREEN}{Colors.BOLD}NO VULNERABILITIES FOUND{Colors.RESET}")

    return {
        'total_vulnerabilities': total_vulnerabilities,
        'by_severity': dict(by_severity)
    }


def generate_summary_report(all_results: Dict[str, Any]) -> str:
    """Generate a final summary report"""
    print_header("SUMMARY REPORT")

    baseline = all_results.get('baseline', {})
    checkov = all_results.get('checkov', {})
    tfsec = all_results.get('tfsec', {})
    trivy = all_results.get('trivy', {})

    # Overall assessment
    has_issues = False
    issues = []

    # Check baseline
    if baseline.get('suspicious_count', 0) > 0:
        has_issues = True
        issues.append(f"{Colors.RED}Baseline has {baseline['suspicious_count']} potentially real secrets{Colors.RESET}")
    if baseline.get('dangerous_files'):
        has_issues = True
        issues.append(f"{Colors.RED}Baseline includes entries from dangerous files{Colors.RESET}")

    # Check Checkov
    if checkov.get('secret_related_count', 0) > 0:
        has_issues = True
        issues.append(f"{Colors.YELLOW}Checkov found {checkov['secret_related_count']} secret-related issues{Colors.RESET}")

    # Check tfsec
    if tfsec.get('total_findings', 0) > 0:
        high_severity = tfsec.get('by_severity', {}).get('HIGH', 0) + tfsec.get('by_severity', {}).get('CRITICAL', 0)
        if high_severity > 0:
            has_issues = True
            issues.append(f"{Colors.YELLOW}tfsec found {high_severity} HIGH/CRITICAL severity issues{Colors.RESET}")

    print(f"{Colors.BOLD}Overall Security Posture:{Colors.RESET}")
    if has_issues:
        print(f"{Colors.YELLOW}{Colors.BOLD}ATTENTION REQUIRED{Colors.RESET}")
        print(f"\n{Colors.BOLD}Issues requiring review:{Colors.RESET}")
        for issue in issues:
            print(f"  • {issue}")
    else:
        print(f"{Colors.GREEN}{Colors.BOLD}GOOD - No critical issues detected{Colors.RESET}")

    print(f"\n{Colors.BOLD}Quick Stats:{Colors.RESET}")
    print(f"  • Baseline findings: {baseline.get('total_findings', 0)}")
    print(f"  • Checkov findings: {checkov.get('total_findings', 0)}")
    print(f"  • tfsec findings: {tfsec.get('total_findings', 0)}")
    print(f"  • Trivy vulnerabilities: {trivy.get('total_vulnerabilities', 0)}")

    print(f"\n{Colors.BLUE}Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.RESET}")

    return "good" if not has_issues else "attention_required"


def main():
    parser = argparse.ArgumentParser(
        description='Review security scan results and secrets baseline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --all                                Review all security reports
  %(prog)s --baseline                           Only review secrets baseline
  %(prog)s --baseline --show-findings           Review baseline with detailed findings
  %(prog)s --baseline --show-findings --limit 5 Show first 5 findings per file
  %(prog)s --baseline --show-findings --show-all Show all findings (no limit)
  %(prog)s --checkov                            Only review Checkov results
        """
    )

    parser.add_argument(
        '--baseline',
        action='store_true',
        help='Analyze the secrets baseline file'
    )
    parser.add_argument(
        '--checkov',
        action='store_true',
        help='Analyze Checkov security results'
    )
    parser.add_argument(
        '--trivy',
        action='store_true',
        help='Analyze Trivy security results'
    )
    parser.add_argument(
        '--tfsec',
        action='store_true',
        help='Analyze tfsec security results'
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Analyze all security reports'
    )
    parser.add_argument(
        '--results-dir',
        type=str,
        default='security-results',
        help='Path to security results directory (default: security-results)'
    )
    parser.add_argument(
        '--show-findings',
        action='store_true',
        help='Show detailed findings with file context (for baseline review)'
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=10,
        metavar='N',
        help='Limit number of findings shown per file (default: 10, use --show-all for unlimited)'
    )
    parser.add_argument(
        '--show-all',
        action='store_true',
        help='Show all findings (ignores --limit)'
    )
    parser.add_argument(
        '--output',
        '-o',
        type=str,
        metavar='FILE',
        help='Save detailed findings report to FILE (text format)'
    )

    args = parser.parse_args()

    # Default to analyzing all if nothing specified
    analyze_all = args.all or not (args.baseline or args.checkov or args.trivy or args.tfsec)

    # Get paths
    project_root = Path(__file__).parent.parent
    baseline_path = project_root / '.secrets.baseline'
    results_dir = project_root / args.results_dir

    # Find latest security reports
    checkov_path = None
    trivy_path = None
    tfsec_path = None

    if results_dir.exists():
        # Find the most recent files for each scanner
        try:
            checkov_files = sorted(results_dir.glob('checkov-*.sarif'), reverse=True)
            if checkov_files:
                checkov_path = checkov_files[0]

            trivy_files = sorted(results_dir.glob('trivy-*.json'), reverse=True)
            if trivy_files:
                trivy_path = trivy_files[0]

            tfsec_files = sorted(results_dir.glob('tfsec-*.json'), reverse=True)
            if tfsec_files:
                tfsec_path = tfsec_files[0]
        except Exception as e:
            print(f"{Colors.YELLOW}Warning: Could not find report files: {e}{Colors.RESET}", file=sys.stderr)

    all_results = {}

    # Prepare output file path if specified
    output_path = None
    if args.output:
        output_path = Path(args.output)

    # Run requested analyses
    if analyze_all or args.baseline:
        all_results['baseline'] = analyze_baseline(
            baseline_path,
            show_findings=args.show_findings,
            findings_limit=args.limit,
            show_all=args.show_all,
            save_to_file=output_path
        )

    if (analyze_all or args.checkov) and checkov_path:
        all_results['checkov'] = analyze_checkov(checkov_path)

    if (analyze_all or args.tfsec) and tfsec_path:
        all_results['tfsec'] = analyze_tfsec(tfsec_path)

    if (analyze_all or args.trivy) and trivy_path:
        all_results['trivy'] = analyze_trivy(trivy_path)

    # Generate summary
    if all_results:
        generate_summary_report(all_results)

    return 0


if __name__ == '__main__':
    sys.exit(main())
