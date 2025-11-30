# Documentation Reorganization - Migration Guide

## Overview

The tf-kube-any-compute documentation has been reorganized for better clarity and maintainability. This guide helps you find relocated documentation.

## What Changed

### Removed Files

**Backup and Temporary Files** (deleted):
- `README.md.backup`
- `git_squash.backup`
- `pr.md.backup`
- `services_output.tf.backup`
- `terraform-working-withldap-and-consul.tfvars.backup`
- `variables.tf.bak`
- `variables.tf.bak2`

**Outdated Review Files** (deleted):
- `CODEBASE-REVIEW.md`
- `QUICK-REVIEW-SUMMARY.md`
- `REVIEW-ACTIONS-COMPLETED.md`
- `SECURITY-FIXES-SUMMARY.md`

**Consolidated Files** (merged into others):
- `CHANGELOG-AUTOMATION-SERVICES.md` → `CHANGELOG.md`
- `CHANGELOG-DNS-PROVIDERS.md` → `CHANGELOG.md`
- `VERSION-ALIGNMENT-REPORT.md` → `docs/reference/VERSION-MANAGEMENT.md`
- `VERSION-UPDATE-CHECKLIST.md` → `docs/reference/VERSION-MANAGEMENT.md`
- `PROJECT.md` → Content integrated into `README.md`
- `README_PALETTE_DOCS.md` → Content already in `README.md`

### New Directory Structure

```
docs/
├── README.md                    # Documentation index
├── guides/                      # User guides
├── reference/                   # Technical reference
├── development/                 # Development guides
├── archive/                     # Historical documents
└── prompts/                     # AI-assisted development prompts
```

## File Location Changes

### Guides (User Documentation)

| Old Location | New Location |
|--------------|--------------|
| `AUTHENTICATION-GUIDE.md` | `docs/guides/AUTHENTICATION-GUIDE.md` |
| `AUTOMATION-SERVICES-GUIDE.md` | `docs/guides/AUTOMATION-SERVICES-GUIDE.md` |
| `AUTOMATION-SERVICES-FIXES.md` | `docs/guides/AUTOMATION-SERVICES-FIXES.md` |
| `SECURITY-HARDENING.md` | `docs/guides/SECURITY-HARDENING.md` |
| `SECURITY-TESTING-GUIDE.md` | `docs/guides/SECURITY-TESTING-GUIDE.md` |
| `TESTING-GUIDE.md` | `docs/guides/TESTING-GUIDE.md` |
| `docs/MIDDLEWARE-GUIDE.md` | `docs/guides/MIDDLEWARE-GUIDE.md` |
| `docs/AUTOMATION-SERVICES-QUICK-START.md` | `docs/guides/AUTOMATION-SERVICES-QUICK-START.md` |

### Reference (Technical Documentation)

| Old Location | New Location |
|--------------|--------------|
| `VARIABLES.md` | `docs/reference/VARIABLES.md` |
| `DNS-PROVIDER-CERT-RESOLVERS.md` | `docs/reference/DNS-PROVIDER-CERT-RESOLVERS.md` |
| `LDAP-AUTHENTICATION-METHODS.md` | `docs/reference/LDAP-AUTHENTICATION-METHODS.md` |
| `VERSION-MANAGEMENT.md` | `docs/reference/VERSION-MANAGEMENT.md` |
| `docs/VERSION-UPDATES.md` | `docs/reference/VERSION-UPDATES.md` |

### Development (Contribution Guides)

| Old Location | New Location |
|--------------|--------------|
| `CONTRIBUTING.md` | `docs/development/CONTRIBUTING.md` (copy kept in root) |
| `CONTRIBUTOR-QUICK-START.md` | `docs/development/CONTRIBUTOR-QUICK-START.md` (copy kept in root) |
| `SERVICE-INTEGRATION-TEMPLATE.md` | `docs/development/SERVICE-INTEGRATION-TEMPLATE.md` |
| `TERRAFORM-DOCS-AUTOMATION.md` | `docs/development/TERRAFORM-DOCS-AUTOMATION.md` |

### Archive (Historical Documents)

| Old Location | New Location |
|--------------|--------------|
| `AUTOMATION-MODULES-PROPOSAL.md` | `docs/archive/AUTOMATION-MODULES-PROPOSAL.md` |
| `MIDDLEWARE-SYSTEM.md` | `docs/archive/MIDDLEWARE-SYSTEM.md` |
| `BREAKING-CHANGES.md` | `docs/archive/BREAKING-CHANGES.md` |
| `CONTRIBUTION-ROADMAP.md` | `docs/archive/CONTRIBUTION-ROADMAP.md` |
| `CONTRIBUTING-MIDDLEWARE.md` | `docs/archive/CONTRIBUTING-MIDDLEWARE.md` |

### AI Prompts

| Old Location | New Location |
|--------------|--------------||
| `prompts/` | `docs/prompts/` |

## Quick Reference

### Finding Documentation

**For Users:**
- Start with [README.md](README.md) for overview and quick start
- Browse [docs/guides/](docs/guides/) for how-to guides
- Check [docs/reference/](docs/reference/) for technical details

**For Contributors:**
- See [docs/development/CONTRIBUTING.md](docs/development/CONTRIBUTING.md) for contribution guidelines
- Use [docs/development/CONTRIBUTOR-QUICK-START.md](docs/development/CONTRIBUTOR-QUICK-START.md) for quick setup
- Reference [docs/development/SERVICE-INTEGRATION-TEMPLATE.md](docs/development/SERVICE-INTEGRATION-TEMPLATE.md) for adding services

**For Reference:**
- [docs/README.md](docs/README.md) - Complete documentation index
- [CHANGELOG.md](CHANGELOG.md) - Unified project changelog
- [docs/reference/VERSION-MANAGEMENT.md](docs/reference/VERSION-MANAGEMENT.md) - Version management system

## Updating Links

If you have bookmarks or scripts referencing old paths, update them as follows:

### Example Updates

```bash
# Old
cat AUTHENTICATION-GUIDE.md

# New
cat docs/guides/AUTHENTICATION-GUIDE.md
```

```bash
# Old
open VARIABLES.md

# New
open docs/reference/VARIABLES.md
```

### Git History

All files retain their git history. Use `git log --follow` to track moved files:

```bash
git log --follow docs/guides/AUTHENTICATION-GUIDE.md
```

## Benefits of New Structure

1. **Clearer Organization**: Documentation grouped by purpose
2. **Easier Navigation**: Logical directory structure
3. **Better Discoverability**: Index file guides users
4. **Reduced Clutter**: Root directory contains only essential files
5. **Improved Maintainability**: Related docs grouped together

## Questions?

- Check [docs/README.md](docs/README.md) for the complete documentation index
- Open an issue if you can't find specific documentation
- See [docs/development/CONTRIBUTING.md](docs/development/CONTRIBUTING.md) for contribution guidelines

---

**Migration Date**: 2025-01-10
**Status**: Complete
