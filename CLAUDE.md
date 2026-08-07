# Claude Context: Claudify

This project uses Claudify, a professional operating system for Claude Code.
Always read `.claude/memory.md` before taking action.

<!-- SYSTEM-SHIPPED:START -->
<!--
  Content between SYSTEM-SHIPPED markers is the Claudify system layer.
  Installing an update (re-download and copy the new .claude/ files over) replaces this section.
  To override a system rule, add a contradicting rule in the CUSTOMER-OWNED section below.
  Local rules win because the auditor reads top-to-bottom.
-->

## Quick Start
- Run `/start` to begin work
- Run `/sync` mid-day to refresh memory
- Run `/wrap-up` at end of day
- Run `/audit` to verify recent work quality
- Run `/test` to write focused tests for a change and run them to prove they pass
- Run `/prove` to force the loop closed on a done-claim, real PASS/FAIL with command evidence
- Run `/mutation-gate` to check your tests actually catch bugs (mutation score on changed files)
- Run `/memory-consolidate` to merge duplicates, expire stale guesses, and prune memory
- Run `/undo-bash` to restore a file a destructive bash command changed (from a safe-run snapshot)
- Run `/verify` to prove a change works by running it, not just reading it
- Run `/security-review` for an adversarial security pass on your diff
- Run `/test-hooks` to prove every shipped hook fires and blocks as documented
- Run `/safe-clear` to safely flush context and resume fresh
- Run `/unstick` when stuck on a problem
- Run `/retro` for sprint retrospective
- Run `/system-audit` for deep infrastructure audit

## Key Files
- Memory: `.claude/memory.md` (read this for current context)
- Knowledge Base: `.claude/knowledge-base.md` (system-wide learned rules, read before every task)
- Task Board: `Task Board.md`
- Scratchpad: `Scratchpad.md` (quick capture, processed during /sync, cleared at /wrap-up)
- Daily Notes: `Daily Notes/` (created automatically by /start)
- Knowledge Nominations: `.claude/knowledge-nominations.md` (candidate learnings, auditor reviews)
- Command Index: `.claude/command-index.md` (all commands with triggers and tools)
- MCP Config: `.mcp.json` (Model Context Protocol servers — filesystem, git, kubernetes, browser, etc.)

## MCP Integration

Claudify integrates with Model Context Protocol (MCP) servers for external capabilities.

### Configured MCPs

| MCP | Purpose | Auto-Approved Tools |
|-----|---------|---------------------|
| filesystem | File operations | read, list, search, directory tree |
| git | Version control | status, diff, commit, add, log, branch |
| memory | Knowledge graph | entities, relations, observations |
| time | Time utilities | current time, timezone convert |
| context7 | Library documentation | Query package docs |
| kubernetes | K8s management | kubectl get, describe |
| playwright | Browser automation | navigate, click, fill, screenshot |

### Configuration

MCPs are configured in `.mcp.json` at the project root.

The filesystem and git MCPs use `$CLAUDE_PROJECT_DIR` to automatically reference the current project.

To enable/disable MCPs or adjust auto-approval settings, edit `.mcp.json`.

See https://modelcontextprotocol.io for available servers.

## System Architecture
- **Agents** (`.claude/agents/`): Specialist subagents with persistent memory
  - `auditor`: Quality gate. Reviews work, promotes knowledge, proposes SOP revisions
  - `unsticker`: Unblocks you when stuck. Root-cause analysis, fresh approaches
  - `error-whisperer`: Translates cryptic errors into fixes. Pattern matching across sessions
  - `rubber-duck`: Forces you to articulate the real problem. Socratic debugging
  - `pr-ghostwriter`: Writes PR descriptions, commit messages, changelogs from diffs
  - `yak-shave-detector`: Catches scope creep. "You started doing X but now you're doing Y"
  - `debt-collector`: Tracks tech debt. Catalogues shortcuts, suggests when to pay them down
  - `onboarding-sherpa`: Learns a new codebase fast. Architecture maps, key-file identification
  - `archaeologist`: Excavates why code exists. Git blame + context reconstruction
  - `verifier`: Runs the project to prove a change works. PASS/FAIL with real command evidence, never a code-reading opinion
  - `security-review`: Adversarial read-only security pass over your diff. Severity-ranked findings with file:line and a concrete fix
  - `test-writer`: Writes focused tests for a change, then hands to verifier to prove they run. PASS/FAIL with real evidence, not a code-reading opinion
- **Commands** (`.claude/commands/`): Workflow rituals and utilities
- **Hooks** (`.claude/hooks/`): Deterministic safety enforcement (logging, verification). Every shipped hook has a proof: run `/test-hooks` to see each one fire and block exactly as documented (tests live in `.claude/hooks/tests/`).
- **Logs** (`.claude/logs/`): Audit trail + incident log, auto-populated by hooks
- **Skills** (`.claude/skills/`): Domain knowledge, loaded on demand

**Commands and skills are one mechanism.** Since July 2026, Claude Code treats them identically: `.claude/commands/name.md` and `.claude/skills/name/SKILL.md` both register `/name`. Claudify keeps workflow rituals in `commands/` and domain knowledge in `skills/` as an organizational convention, not a platform distinction. New slash commands you author may use either format.

**Subagent defaults (Claude Code 2.1.198+):** subagents run in the background by default. Every shipped command that consumes a subagent's verdict in-procedure states `run_in_background: false` at the spawn step; do the same in your own pipelines. Nested spawning (an agent spawning agents) is opt-in via the `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` environment variable; this template presets it to 2 in `.claude/settings.json`. Concurrency caps: 20 subagents at once, 200 per session. No shipped Claudify pipeline comes near either cap.

**Hook matcher semantics (July 2026):** matchers containing a hyphen are now exact-match; use `mcp__server__.*` to cover a whole MCP server. Comma lists (`"auto,manual"`) fire on each listed value. In `if:` conditions, a single-segment `dir/**` glob is cwd-only; use `**/dir/**` to match at any depth. All shipped matchers were audited against these rules and none were affected.

## Memory Architecture (6 Tiers)
1. **memory.md**: Active session context (what you're doing now)
2. **Agent Memory** (`.claude/agent-memory/`): Per-agent persistent knowledge across sessions
3. **Knowledge Base** (`.claude/knowledge-base.md`): System-wide learned rules (auditor-gated)
4. **Knowledge Nominations** (`.claude/knowledge-nominations.md`): Candidate learnings pipeline
5. **MCP Knowledge Graph**: Structured entities and relations (if memory MCP enabled)
6. **Daily Notes**: Chronological session history and handoff records

## Command Awareness

All agents can invoke system commands. Read `.claude/command-index.md` for the full catalog.

- **Self-execute**: If you have the tools a command requires, read `.claude/commands/{name}.md` and follow the procedure directly.
- **Recommend**: If you lack the tools, output `RECOMMEND: /command [args]: [reason]` for the orchestrator.
- Agents should proactively invoke commands when trigger conditions match.

## Retrieval Map: Where to look for what

| You need... | Check first | Then |
|---|---|---|
| What am I doing right now? | `memory.md` → Now | Task Board → Today |
| How to do a procedure | `.claude/commands/` or `.claude/skills/` | CLAUDE.md |
| A fact or learned rule | `knowledge-base.md` | Agent memory |
| What happened on a specific day | `Daily Notes/MMDDYY.md` | Audit trail |
| What went wrong before | `knowledge-base.md` → Hard Rules | Agent memory → Known Patterns |
| What commands exist | `.claude/command-index.md` | `.claude/commands/{name}.md` |

## Context Health (context autopilot)

Sessions have finite context. The default model's native 1M context window (Sonnet 5, June 2026) makes overflow rare in normal sessions, and when it does approach, the flush is automatic. Nobody watches a gauge. Three rules make that lossless:

1. **Keep the handoff warm.** At every natural task boundary (a phase finishing, a domain switch), refresh a short Session Handoff (Task, Done, Remaining, Decisions, Files, Refs, Next) in today's daily note. An excellent handoff is always on disk.
2. **The flush is automatic.** Claude Code auto-compacts on its own when context fills. Claude never tells the user to flush and never runs `/safe-clear` for quality reasons. Manual `/safe-clear` followed by `/compact` stays available if the USER wants an explicit distill; Claude never requests it.
3. **Resume is deterministic.** The `PostCompact` hook surfaces the latest handoff and instructs the resumed session to continue the Next action without asking. The honest limit, stated plainly: an early forced flush at a chosen quality point is not possible (a command cannot reduce its own context); the warm handoff makes the automatic one lossless.

**Automatic safety net (hooks):**
- `PreCompact` hook saves state before compaction (auto and manual)
- `PostCompact` hook restores context after compaction (no marker files, no stale state)
- `SessionStart(compact)` hook remains wired as a fallback for Claude Code versions without the PostCompact event; scheduled for removal in September
- `SessionStart(user)` hook resets stale gate files on every fresh session
- `SubagentStart` hook injects each subagent's mandatory reads (knowledge base + its own memory) so agents cannot forget the rulebook
- `StopFailure` hook logs any quality-gate hook that fails to run, so the trust layer reports its own failures
- `claim-check` + `safe-run` hooks are active: `claim-check` (Stop, SubagentStop) flags done-claims that lack evidence so they get proven not trusted, and `safe-run` (PreToolUse Bash) snapshots files before a destructive bash command so `/undo-bash` can restore them

**Completeness gates (PreToolUse Write|Edit, hard blocks):**
- **knowledge-base.md**: Every entry needs `[Source:]` provenance, max 200 lines, no TBD/TODO
- **memory.md**: Max 100 lines (Write only)
- **settings.json**: Must be valid JSON (broken JSON breaks all hooks)
- **Agent defs** (`.claude/agents/*.md`): No TBD/TODO. Instructions must be definitive.
- **Ungated** (iterative by nature): Daily Notes, Scratchpad, Templates, Logs, Commands, Skills

**How /safe-clear works (user-initiated only):** Distills session state into memory.md + a daily note handoff, preserving retrieval paths, then STOPS and instructs the user to run `/compact`. The PostCompact hook reads the handoff and continues from Next. A command cannot reduce its own context (every read inside it adds tokens), so `/safe-clear` never auto-resumes and Claude never recommends it proactively.

## Maintenance
- Keep memory.md compact (<100 lines)
- Aggressively prune stale items
- Done list cleared on Fridays
- Review incident log during /sync and /wrap-up
- Auditor proposes SOP revisions. User approves before changes apply.

<!-- SYSTEM-SHIPPED:END -->

<!-- CUSTOMER-OWNED:START -->
<!--
  Content between CUSTOMER-OWNED markers is YOURS.
  Installing an update will never modify anything in this section.
  Add your project-specific orientation, overrides, and conventions here.
  Rules in this section win over SYSTEM-SHIPPED rules (auditor reads top-to-bottom).
-->

## This project

**tf-kube-any-compute** — Universal Kubernetes infrastructure platform built entirely in Terraform. Deploys 21+ production-grade services across any Kubernetes distribution (K3s, MicroK8s, EKS, GKE, AKS) and any CPU architecture (ARM64/AMD64, including mixed clusters).

**Key value proposition**: Platform-agnostic, architecture-aware, homelab-focused infrastructure with intelligent auto-detection and flexible configuration hierarchy.

## Project conventions

### Core Architectural Patterns (8 Critical Patterns)

1. **Configuration Override Hierarchy** (5-Level Priority System)
   1. System defaults (hardcoded)
   2. Service defaults (per-service baseline)
   3. User variables (terraform.tfvars)
   4. Service overrides (fine-grained control)
   5. Auto-detection (runtime cluster analysis)

2. **Module Count Pattern** — Module outputs are lists, always use `[0]` index
3. **Two-Step Authentication Deployment** — Core services first, then middleware
4. **CPU Architecture Auto-Detection** — Handles ARM64/AMD64/mixed clusters
5. **DNS Provider = Certificate Resolver Name** — Clear naming convention
6. **Storage Class Selection Logic** — Priority chain for storage
7. **Module Reference Pattern** — Service discovery via module outputs
8. **Workspace-Aware Kubeconfig Detection** — Automatic kubeconfig selection

### Service Deployment Patterns

- **Helm Chart** (most services): `helm_release` with template values
- **Native Kubernetes** (Redis, n8n): Direct `kubernetes_deployment`, `kubernetes_service`

### Testing & Quality Standards

- Run `make test-safe` for fast validation (~2-5 min)
- Run `make test-all` for comprehensive testing
- Use pre-commit hooks: terraform fmt, terraform-docs, tflint, checkov, terrascan
- Test coverage: Unit tests, scenario tests, integration tests, security scanning

### Development Workflow

1. Make changes to module files
2. Run `make test-safe` for fast validation feedback
3. Check pre-commit with `make lint`
4. Update documentation (auto-generated via terraform-docs)
5. Test on both architectures if applicable (ARM64 and AMD64)
6. Update CHANGELOG for user-visible changes
7. Use conventional commits: `feat(scope)`, `fix(scope)`, etc.

### Important Gotchas

1. **CRD Dependencies**: Services using CRDs must depend on CRD deployment first
2. **Helm Timeouts**: Simple 180s, Monitoring 900s, Vault/Consul 600s
3. **Mixed Clusters**: Auto-configure with `auto_mixed_cluster_mode = true`
4. **Secret Management**: Auto-generated passwords when variables empty
5. **Workspace Naming**: `{workspace}-{service}-system` format
6. **Storage Classes**: Always verify exists before using
7. **Module Output Access**: When using `count` pattern, outputs are lists: `module.service[0].output_name`
8. **Authentication Order**: Deploy core services first, then enable middleware

## Local context

### Repository Overview

**tf-kube-any-compute** is a universal Kubernetes infrastructure platform built entirely in Terraform. It deploys **21+ production-grade services** (monitoring, security, automation, platform services) across any Kubernetes distribution (K3s, MicroK8s, EKS, GKE, AKS) and any CPU architecture (ARM64/AMD64, including mixed clusters).

**Key value proposition**: Platform-agnostic, architecture-aware, homelab-focused infrastructure with intelligent auto-detection and flexible configuration hierarchy.

**Recent additions** (2025-2026):

- **Redis** - Native Kubernetes deployment for caching and session storage
- **Authelia** - SSO/2FA with LDAP and OIDC integration
- **Headlamp** - Kubernetes dashboard with LDAP authentication
- **KubeVirt** - Virtual machine management (renamed from helm-kubevirt to kubevirt-operator)

### Common Development Commands

```bash
# Initialize and validate
make init                  # Terraform init + validate + format check
terraform workspace new <name>  # Create environment workspace

# Planning and deployment
make plan                  # Preview infrastructure changes
make apply                 # Deploy infrastructure

# Testing (non-destructive, fast feedback)
make test-safe             # Format, validate, lint only
make test-unit             # Terraform unit tests
make test-scenarios        # Real-world scenario tests

# Full testing suite
make test-all              # Comprehensive tests (includes integration/security/performance)

# Diagnostics and debugging
make debug                 # Comprehensive cluster diagnostics
./scripts/debug.sh         # Detailed cluster health check

# Linting and formatting
make lint                  # Optimized linting (~2-5 min)
make fmt                   # Format Terraform files
terraform fmt -recursive   # Format all .tf files
```

### High-Level Architecture

**Root Module Structure** (4,476 lines total):

- **main.tf**: Module orchestration with `count` pattern for conditional service enablement
- **variables.tf**: All input variables (1,575 lines, alphabetically organized)
- **locals.tf**: Configuration computation engine - architecture detection, storage selection, override hierarchy (1,170 lines)
- **outputs.tf**: Service URLs, access information, debug outputs (677 lines)

**Service Module Pattern**: Every service follows this consistent structure with main.tf, variables.tf, outputs.tf, locals.tf, version.tf, templates/, and optional traefik-ingress.tf, pvc.tf, limit_range.tf, and README.md.

**Deployment Patterns**:

1. **Helm Chart Deployment** (most services) - Uses `helm_release` resource with template-based values via `.yaml.tpl` files and chart version pinning
2. **Native Kubernetes Deployment** (Redis, some specialized services) - Uses `kubernetes_deployment`, `kubernetes_service`, `kubernetes_configmap` for direct resource management

### Critical Architectural Patterns

1. **Configuration Override Hierarchy** (5-Level Priority System): System defaults → Service defaults → User variables → Service overrides → Auto-detection
2. **Two-Step Authentication Deployment**: Deploy core services with `middleware_overrides.enabled = false`, then enable and reapply
3. **CPU Architecture Auto-Detection**: System queries cluster nodes to detect architecture (ARM64/AMD64) and identifies mixed clusters automatically
4. **DNS Provider = Certificate Resolver Name**: Certificate resolvers named after DNS providers (e.g., "cloudflare", "route53", "hurricane")
5. **Storage Class Selection Logic**: Priority chain for storage selection (user override → NFS CSI → HostPath → auto-detected → "default")
6. **Module Count Pattern**: Top-level module enablement uses `count` pattern, always use `[0]` index when referencing outputs
7. **Module Reference Pattern for Service Discovery**: Services automatically discover and reference other services via module outputs
8. **Workspace-Aware Kubeconfig Detection**: Services requiring external kubectl access automatically detect kubeconfig files based on workspace prefix

### Service Categories and Dependencies

**Core Infrastructure** (typically required): Node Feature Discovery, Storage (NFS CSI / HostPath), MetalLB, Traefik

**Monitoring Stack**: Prometheus CRDs, Prometheus Stack, Grafana, Kube-State-Metrics, Metrics Server

**Platform Services** (optional): Vault + Consul, Portainer, Authelia, Redis, Gatekeeper, Headlamp, KubeVirt

**Automation Services** (optional): Home Assistant, openHAB, Homebridge, Node-RED, n8n

### Important Gotchas

1. **CRD Dependencies**: Services using CRDs must depend on CRD deployment first
2. **Helm Timeouts**: Simple 180s, Monitoring 900s, Vault/Consul 600s
3. **Mixed Clusters**: Auto-configure with `auto_mixed_cluster_mode = true`
4. **Secret Management**: Auto-generated passwords when variables empty
5. **Workspace Naming**: `{workspace}-{service}-system` format
6. **Storage Classes**: Always verify exists before using
7. **Module Output Access**: When using `count` pattern, outputs are lists: `module.service[0].output_name`
8. **Authentication Order**: Deploy core services first, then enable middleware

### Project Rules

**No Live Kubernetes Changes**:

- **NEVER make direct changes to Kubernetes using kubectl/helm outside of Terraform**
- All infrastructure changes MUST go through Terraform
- If you need to test something manually, note it for documentation but don't consider it permanent
- Terraform is the single source of truth for cluster state
- Exception: Emergency incident response (document post-incident)

### Documentation Structure
- **Guides** (`docs/guides/`): Authentication, automation, security, testing
- **Reference** (`docs/reference/`): Variables, DNS providers, LDAP, versions
- **Development** (`docs/development/`): Contributing, service integration, quick start
- **Archive** (`docs/archive/`): Historical documentation

### Development Workflow

1. **Make changes** to module files
2. **Run `make test-safe`** for fast validation feedback (~2-5 min)
3. **Check pre-commit** with `make lint`
4. **Update documentation** - terraform-docs auto-generates via pre-commit hook
5. **Test on both architectures** if applicable (ARM64 and AMD64)
6. **Update CHANGELOG** for user-visible changes
7. **Use conventional commits**: `feat(scope): description`, `fix(scope): description`, etc.

### Testing Strategy

- **Unit tests** (`tests.tftest.hcl`): Architecture detection, storage selection, configuration merge logic
- **Scenario tests** (`test-scenarios.tftest.hcl`): ARM64 Pi deployment, AMD64 cloud, mixed clusters
- **Integration tests** (`scripts/integration-tests.sh`): Service health, ingress connectivity, authentication
- **Performance tests** (`scripts/performance-test.js`): Load testing with k6

### Key Files Reference

**Core Configuration Files**:
- **terraform.tfvars.example** (38KB): Complete configuration template with inline comments
- **Makefile** (495 lines): All automation commands
- **locals.tf** (1,170 lines): Architecture detection, override hierarchy, storage logic
- **README.md** (27KB+): User-facing project overview

**Documentation Files**:
- **CONTRIBUTING.md** (19KB): Comprehensive contribution guidelines
- **CONTRIBUTOR-ROADMAP.md**: Strategic improvement roadmap and integration opportunities
- **docs/development/ARCHITECTURE-DECISIONS.md**: Core principles, ADRs, and coding standards
- **CHANGELOG.md**: Version history and user-visible changes

### Contributor Guidance

**Strategic Improvement Areas** from CONTRIBUTOR-ROADMAP.md:

- **Developer Experience & Automation**: Pre-commit hook optimization, automated PR validation, interactive setup scripts
- **Service Ecosystem Expansion**: Priority 1 - Falco (security), ArgoCD (GitOps), Thanos (long-term storage)
- **Testing & Quality Assurance**: Module-specific test suites, performance baseline testing, upgrade path validation
- **Documentation & Knowledge Management**: Architecture Decision Records (ADRs), service-specific troubleshooting guides

**Contribution Pathways**:
- **Beginner-Friendly**: Add missing examples, create troubleshooting guides, improve inline comments, add unit tests
- **Intermediate**: Add new services, improve existing modules, enhance architecture detection
- **Advanced**: Multi-cluster management, advanced service mesh integration, edge computing optimizations

### Success Metrics

- Test coverage: >80% for new modules
- Documentation completeness: All sections filled
- Pre-commit runtime: <2 minutes for validation
- PR response time: <48 hours for initial review
- Security scans: Zero high/critical findings

### Documentation Quality Standards

Based on the recent documentation audit (Redis, Authelia, Headlamp, KubeVirt), all module READMEs should include:

**Essential Sections**:
1. Features List: Bullet points of key capabilities
2. Usage Examples: Both basic and advanced configuration
3. Configuration Variables: Complete table with types and defaults
4. Architecture Support: ARM64/AMD64/mixed cluster compatibility
5. Troubleshooting: Common issues and solutions

**Specialized Sections** (as needed):
- Integration Patterns: Module reference examples for service discovery
- Authentication Guide: LDAP, OIDC, or other auth mechanisms
- Storage Configuration: PVC requirements and recommendations
- Monitoring Setup: ServiceMonitor and Prometheus integration
- Namespace Cleanup: Special cleanup procedures if needed

**Documentation Anti-Patterns to Avoid**:
1. Implementation Mismatch: Documentation describing Helm when code uses native Kubernetes
2. Missing Variables: Documented variables not matching variables.tf
3. Outdated Paths: References to renamed modules or moved files
4. Incomplete Examples: Examples that don't demonstrate key features
5. Broken Links: References to non-existent documentation or guides

### Recent Learnings & Patterns (2026)

**Documentation Audit Insights**:

1. Implementation-Documentation Mismatch: Always verify README matches actual implementation pattern (Helm vs native Kubernetes)
2. Missing Module Reference Documentation: Document module output references for service integration patterns
3. Incomplete Variable Documentation: Ensure all variables in variables.tf appear in README documentation
4. Outdated Module Paths: Update source paths and examples when modules are renamed

**Module Integration Patterns**:

- Module Reference Pattern (preferred): `module.service_b { dependency_module_reference = module.service_a[0].output_name }`
- Manual Configuration Pattern (fallback): `dependency_host = "service-a.namespace.svc.cluster.local"`

**Native Kubernetes vs Helm Decision Tree**:

1. Does a high-quality Helm chart exist? Yes → Use Helm, No → Consider native Kubernetes
2. Is the service simple and stateless? Yes → Native Kubernetes acceptable, No → Use Helm
3. Do we need deep customization? Yes → Native Kubernetes may be simpler, No → Helm values sufficient

**Workspace-Aware Configuration Pattern**: For services requiring external cluster access, automatically detect kubeconfig files based on workspace prefix: check `kubeconfig_path`, then `ci_mode` with `KUBECONFIG`, then construct from `workspace_prefix`, fallback to default.

### Additional Resources

**For AI Assistants**:
1. CLAUDE.md (this file): Architectural patterns and critical gotchas
2. CONTRIBUTING.md: Development workflow and testing requirements
3. CONTRIBUTOR-ROADMAP.md: Strategic priorities and improvement areas
4. Module READMEs: Service-specific documentation and examples
5. terraform.tfvars.example: Complete configuration reference

**For New Contributors**:
1. README.md: Project overview and quick start
2. CONTRIBUTING-QUICK-START.md: Fast path to contributions
3. docs/development/SERVICE-INTEGRATION-TEMPLATE.md: Module integration checklist
4. CONTRIBUTOR-ROADMAP.md: High-impact improvement opportunities

**For Maintainers**:
1. CHANGELOG.md: Version history and release notes
2. docs/archive/: Historical context for deprecated features
3. Security scans: Review in security-results/ directory
4. Test results: Check GitHub Actions or CI logs

<!-- CUSTOMER-OWNED:END -->
## Retrieval Map — Where to look for what

| You need... | Check first | Then |
|---|---|---|
| What am I doing right now? | `memory.md` → Now | Task Board → Today |
| How to do a procedure | `.claude/commands/` or `.claude/skills/` | CLAUDE.md |
| A fact or learned rule | `knowledge-base.md` | Agent memory |
| What happened on a specific day | `Daily Notes/MMDDYY.md` | Audit trail |
| What went wrong before | `knowledge-base.md` → Hard Rules | Agent memory → Known Patterns |
| What commands exist | `.claude/command-index.md` | `.claude/commands/{name}.md` |

## Context Health

Sessions have finite context. Heavy operations consume it fast.

**Automatic safety net (hooks):**
- `PreCompact` hook saves state before auto-compaction
- `SessionStart(compact)` hook restores context after compaction
- `SessionStart(user)` hook resets stale gate files on every fresh session
- `claim-check` + `safe-run` hooks are active: `claim-check` (Stop, SubagentStop) flags done-claims that lack evidence so they get proven not trusted, and `safe-run` (PreToolUse Bash) snapshots files before a destructive bash command so `/undo-bash` can restore them

**Completeness gates (PreToolUse Write|Edit, hard blocks):**
- **knowledge-base.md**: Every entry needs `[Source:]` provenance, max 200 lines, no TBD/TODO
- **memory.md**: Max 100 lines (Write only)
- **settings.json**: Must be valid JSON (broken JSON breaks all hooks)
- **Agent defs** (`.claude/agents/*.md`): No TBD/TODO — instructions must be definitive
- **Ungated** (iterative by nature): Daily Notes, Scratchpad, Templates, Logs, Commands, Skills

**Self-monitoring (soft signals — Claude's responsibility):**
- After ~30+ tool calls or 3+ large file reads: run `/safe-clear` proactively
- If you see a "compacting conversation" warning: run `/safe-clear` immediately
- If output quality degrades (repetition, missed details): run `/safe-clear`
- When a discrete multi-step task completes: consider `/safe-clear` before starting the next unrelated task
- When switching between different task domains: acknowledge the boundary, prefer `/safe-clear` for heavy switches

**How /safe-clear works:** Distills session state into memory.md + daily note handoff, preserving retrieval paths. Then automatically resumes work by reloading compressed context and executing the next action. Seamless to the user.
