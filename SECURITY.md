# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via:
- GitHub Security Advisories (preferred)
- Email to the maintainers (see README for contact info)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Security Features

This project includes:
- Automated security scanning (Checkov, TFSec, Trivy)
- Resource limits and security contexts
- Network policies and RBAC
- Secrets management with Vault
- SSL/TLS encryption by default

## Security Best Practices

When using this module:
- Always use the latest version
- Enable Gatekeeper policies in production
- Regularly update Helm charts
- Monitor security scan results
- Use strong passwords and rotate them regularly
- Enable resource limits
- Review and customize security policies

## Response Timeline

- Initial response: Within 48 hours
- Status update: Within 7 days
- Resolution target: Within 30 days (depending on complexity)
