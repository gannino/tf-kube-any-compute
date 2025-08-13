I need to implement terraform-docs automation that works seamlessly in both CI/CD pipelines and local development with pre-commit hooks for my Terraform Kubernetes infrastructure project.

Requirements:

1. **CI/CD Integration** that:
   - Automatically generates and validates terraform-docs output
   - Fails CI if documentation is out of date
   - Uses consistent terraform-docs version across environments
   - Integrates with existing GitHub Actions workflow
   - Provides clear error messages when docs are outdated

2. **Local Pre-commit Hook** that:
   - Auto-generates terraform-docs before commits
   - Updates README.md automatically with latest Terraform configuration
   - Uses same terraform-docs version as CI
   - Handles multiple Terraform modules/directories
   - Integrates with existing git workflow

3. **Version Management** that:
   - Centralized terraform-docs version in .github/versions.yml
   - Consistent versions between CI and local development
   - Easy version updates across all environments

4. **Configuration Standards** for:
   - terraform-docs output format (markdown table)
   - Section placement in README.md (between <!-- BEGIN_TF_DOCS --> and <!-- END_TF_DOCS -->)
   - Module-specific documentation
   - Automatic sorting and formatting

5. **Error Handling** that:
   - Clear feedback when docs are missing or outdated
   - Instructions for developers to fix documentation issues
   - Graceful handling of terraform-docs installation failures

Implementation needs:
- .pre-commit-config.yaml configuration
- GitHub Actions workflow integration
- Makefile commands for manual execution
- Installation scripts for local development
- Documentation validation logic

Focus on developer experience, CI reliability, and maintaining up-to-date documentation automatically.
