## 📋 **Pull Request Summary**

**Please fill out this template to help us review your PR efficiently.**

### **Type of Change**
<!-- Mark the type of change this PR represents -->

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to change)
- [ ] 📚 Documentation update
- [ ] 🧪 Test improvements
- [ ] 🔧 Maintenance (dependency updates, code cleanup)
- [ ] 🛡️ Security improvement

### **Related Issues**
<!-- Link any related issues -->
Closes #(issue number)
Related to #(issue number)

### **Description**
<!-- Provide a clear description of the changes and the motivation behind them -->

**What does this PR do?**

**Why are these changes needed?**

### **Testing Performed**
<!-- Describe the testing you have performed -->

**Automated Tests:**

- [ ] `make test-safe` passes
- [ ] `make test-validate` passes
- [ ] `make test-scenarios` passes
- [ ] CI pipeline passes

**Manual Testing:**

- [ ] Tested on [Platform: K3s/MicroK8s/Cloud]
- [ ] Tested on [Architecture: ARM64/AMD64/Mixed]
- [ ] Services deploy successfully
- [ ] Ingress/networking functional
- [ ] Monitoring/observability working

### **Configuration Tested**
<!-- Include a snippet of your test configuration -->

```hcl
# terraform.tfvars used for testing
base_domain = "test.local"
platform_name = "k3s"
services = {
  # ... configuration details
}
```

### **Deployment Verification**
<!-- Verify these aspects work correctly -->

- [ ] All enabled services start successfully
- [ ] Ingress routes are accessible
- [ ] SSL certificates are issued (if applicable)
- [ ] Monitoring dashboards are functional
- [ ] No resource conflicts or errors
- [ ] Prometheus/Grafana showing metrics (if enabled)

### **Breaking Changes**
<!-- If this introduces breaking changes, describe them -->

**Does this PR introduce breaking changes?**

- [ ] Yes
- [ ] No

**If yes, describe:**

1. **What breaks:**
2. **Migration path:**
3. **Version impact:**

### **Documentation Updates**
<!-- Confirm documentation is updated -->

- [ ] README.md updated (if needed)
- [ ] CHANGELOG.md updated
- [ ] Service module README updated (if applicable)
- [ ] Configuration examples updated (if needed)
- [ ] Troubleshooting guides updated (if applicable)

### **Security Considerations**
<!-- Address any security implications -->

- [ ] No new security vulnerabilities introduced
- [ ] Secrets are properly managed
- [ ] RBAC permissions are appropriate
- [ ] Network policies are considered

### **Performance Impact**
<!-- Consider performance implications -->

- [ ] No negative performance impact
- [ ] Resource usage is reasonable
- [ ] Scaling characteristics are appropriate

### **Additional Context**
<!-- Any additional information that would help reviewers -->

**Screenshots (if applicable):**

**Additional notes:**

---

## **Reviewer Checklist**
<!-- For maintainers reviewing this PR -->

- [ ] Code follows project style and conventions
- [ ] All tests pass and coverage is adequate
- [ ] Documentation is complete and accurate
- [ ] Security implications have been considered
- [ ] Performance impact is acceptable
- [ ] Breaking changes are properly documented
- [ ] Migration path is clear (if applicable)
