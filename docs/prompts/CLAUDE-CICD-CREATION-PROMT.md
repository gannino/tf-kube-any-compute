I need to implement comprehensive CI testing for my Terraform Kubernetes infrastructure project. Based on the attached documentation, create:

1. **Enhanced GitHub Actions CI workflow** that:
   - Runs validation, unit tests, scenario tests in parallel
   - Uses Terraform 1.12.2 and TFLint v0.47.0 from versions.yml
   - Tests multiple deployment scenarios without provisioning infrastructure
   - Includes security scanning and documentation checks
   - Provides clear reporting and artifact management

2. **Terraform native test files** for:
   - Architecture detection logic (ARM64/AMD64/mixed clusters)
   - Storage configuration (NFS/hostpath selection)
   - Service enablement logic
   - Mixed cluster configuration validation

3. **Updated Makefile commands** for:
   - CI-specific test execution
   - Parallel unit test categories
   - Scenario-based testing
   - Security scanning integration

4. **Test scenario configurations** for:
   - Raspberry Pi ARM64 clusters
   - Mixed architecture deployments
   - Cloud provider configurations
   - Minimal homelab setups

Requirements:
- No actual infrastructure provisioning in CI
- Use `terraform plan` for validation
- Fast feedback with parallel execution
- Comprehensive coverage of configuration logic
- Integration with existing make commands
- Clear error reporting and debugging artifacts

Focus on reliability, speed, and maintainability for a production-ready CI pipeline.
