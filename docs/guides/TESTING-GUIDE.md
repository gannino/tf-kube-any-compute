# 🧪 Testing Guide for tf-kube-any-compute

This guide provides comprehensive information about testing the tf-kube-any-compute project, from basic validation to advanced integration testing.

## 📋 Testing Overview

Our testing strategy includes multiple layers:

1. **Static Analysis** - Code formatting, linting, security scanning
2. **Unit Tests** - Logic validation without deployment
3. **Scenario Tests** - Configuration validation for different use cases
4. **Integration Tests** - Live testing with deployed infrastructure
5. **Performance Tests** - Load testing and response time validation
6. **Security Tests** - Vulnerability scanning and policy validation

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
terraform >= 1.0
kubectl
helm >= 3.0
make

# Optional tools for enhanced testing
tflint      # Terraform linting
trivy       # Security scanning
k6          # Performance testing
pre-commit  # Git hooks
```

### Basic Test Commands

```bash
# Quick validation (recommended for development)
make test-safe

# Comprehensive testing
make test-all

# Specific test types
make test-lint      # Formatting and linting
make test-unit      # Unit tests
make test-scenarios # Scenario tests
make test-security  # Security scanning
```

## 🔍 Static Analysis

### Formatting and Linting

```bash
# Check Terraform formatting
make fmt-check

# Auto-format Terraform files
make fmt

# Run TFLint analysis
make lint

# Comprehensive linting
make test-lint
```

### Security Scanning

```bash
# Run all security tests
make test-security

# Individual security tools
make test-security-trivy     # Vulnerability scanning
make test-security-checkov   # Policy validation
make test-security-secrets   # Secret detection
```

## 🧪 Unit Testing

Unit tests validate configuration logic without deploying resources.

### Running Unit Tests

```bash
# Run all unit tests
make test-unit

# Run with verbose output
terraform test -filter=tests.tftest.hcl -verbose

# Test specific functionality
terraform test -filter=tests.tftest.hcl -verbose -var="cpu_arch=arm64"
```

### Unit Test Structure

```hcl
# tests.tftest.hcl
variables {
  # Default test variables
  cpu_arch = "amd64"
  services = {
    traefik    = true
    prometheus = true
    grafana    = true
  }
}

run "test_architecture_detection" {
  command = plan

  variables {
    cpu_arch = "arm64"
  }

  assert {
    condition     = local.detected_cpu_arch == "arm64"
    error_message = "Architecture detection failed"
  }
}

run "test_storage_class_selection" {
  command = plan

  variables {
    use_nfs_storage = true
    nfs_server_address = "192.168.1.100"
  }

  assert {
    condition     = local.storage_class == "nfs-csi"
    error_message = "NFS storage class not selected correctly"
  }
}
```

### Writing New Unit Tests

1. **Test Configuration Logic**:
   ```hcl
   run "test_service_enablement" {
     command = plan

     variables {
       services = {
         prometheus = true
         grafana    = false
       }
     }

     assert {
       condition = local.enabled_services.prometheus == true
       error_message = "Prometheus should be enabled"
     }

     assert {
       condition = local.enabled_services.grafana == false
       error_message = "Grafana should be disabled"
     }
   }
   ```

2. **Test Variable Validation**:
   ```hcl
   run "test_invalid_cpu_arch" {
     command = plan

     variables {
       cpu_arch = "invalid"
     }

     expect_failures = [
       var.cpu_arch
     ]
   }
   ```

## 🎯 Scenario Testing

Scenario tests validate different deployment configurations.

### Running Scenario Tests

```bash
# Run all scenario tests
make test-scenarios

# Run with verbose output
terraform test -filter=test-scenarios.tftest.hcl -verbose

# Test specific scenarios using config files
make ci-test-scenarios
```

### Available Test Scenarios

1. **Raspberry Pi Cluster** (`test-configs/raspberry-pi.tfvars`):
   ```hcl
   cpu_arch = "arm64"
   enable_microk8s_mode = true
   use_hostpath_storage = true
   services = {
     traefik    = true
     metallb    = true
     prometheus = true
     grafana    = true
   }
   ```

2. **Cloud Deployment** (`test-configs/cloud.tfvars`):
   ```hcl
   cpu_arch = "amd64"
   use_nfs_storage = false
   use_hostpath_storage = false
   services = {
     traefik    = true
     prometheus = true
     grafana    = true
     consul     = true
     vault      = true
   }
   ```

3. **Mixed Architecture** (`test-configs/mixed-cluster.tfvars`):
   ```hcl
   auto_mixed_cluster_mode = true
   cpu_arch_override = {
     prometheus = "amd64"
     grafana    = "arm64"
   }
   ```

### Creating New Scenarios

1. **Create Configuration File**:
   ```bash
   # Create new scenario config
   cat > test-configs/my-scenario.tfvars << EOF
   # My custom scenario
   cpu_arch = "arm64"
   services = {
     traefik = true
     grafana = true
   }
   EOF
   ```

2. **Add to CI Tests**:
   ```bash
   # Edit Makefile to include new scenario
   # Add "my-scenario" to ci-test-scenarios target
   ```

3. **Write Scenario Test**:
   ```hcl
   # Add to test-scenarios.tftest.hcl
   run "test_my_scenario" {
     command = plan

     variables {
       # Load from config file or define inline
     }

     assert {
       condition = # Your validation logic
       error_message = "Scenario validation failed"
     }
   }
   ```

## 🔗 Integration Testing

Integration tests validate deployed infrastructure functionality.

### Prerequisites for Integration Tests

```bash
# Ensure you have a running Kubernetes cluster
kubectl cluster-info

# Deploy infrastructure first
make apply

# Then run integration tests
make test-integration
```

### Integration Test Categories

1. **Service Health Checks**:
   ```bash
   # Check if services are running
   kubectl get pods --all-namespaces
   kubectl get services --all-namespaces
   kubectl get ingresses --all-namespaces
   ```

2. **Connectivity Tests**:
   ```bash
   # Test internal connectivity
   kubectl run test-pod --image=curlimages/curl --rm -it -- /bin/sh
   # Inside pod: curl http://service-name.namespace.svc.cluster.local
   ```

3. **Ingress Functionality**:
   ```bash
   # Test external access
   curl -k https://grafana.your-domain.com
   curl -k https://traefik.your-domain.com/dashboard/
   ```

### Custom Integration Tests

Create `scripts/custom-integration-test.sh`:

```bash
#!/bin/bash
set -e

echo "🧪 Running custom integration tests..."

# Test Prometheus metrics
echo "Testing Prometheus..."
kubectl port-forward -n monitoring svc/prometheus-server 9090:80 &
PF_PID=$!
sleep 5
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result | length'
kill $PF_PID

# Test Grafana dashboard
echo "Testing Grafana..."
kubectl port-forward -n grafana svc/grafana 3000:80 &
PF_PID=$!
sleep 5
curl -s http://localhost:3000/api/health | jq '.database'
kill $PF_PID

echo "✅ Custom integration tests passed!"
```

## ⚡ Performance Testing

Performance tests validate system responsiveness and load handling.

### Prerequisites

```bash
# Install k6 for performance testing
brew install k6
# or
curl https://github.com/grafana/k6/releases/download/v0.45.0/k6-v0.45.0-linux-amd64.tar.gz -L | tar xvz --strip-components 1
```

### Running Performance Tests

```bash
# Run performance tests
make test-performance

# Run specific performance test
k6 run scripts/performance-test.js

# Run with custom parameters
k6 run --vus 10 --duration 30s scripts/performance-test.js
```

### Performance Test Scenarios

The `scripts/performance-test.js` includes:

1. **Traefik Ingress Performance**:
   - Response time validation
   - Throughput testing
   - SSL termination performance

2. **Grafana Dashboard Loading**:
   - Dashboard load times
   - API response times
   - Concurrent user simulation

3. **Service Discovery Latency**:
   - Consul API performance
   - Service registration time
   - Health check responsiveness

### Custom Performance Tests

```javascript
// custom-performance-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 10,
  duration: '30s',
};

export default function() {
  // Test your service
  let response = http.get('https://your-service.domain.com');

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

## 🛡️ Security Testing

Security tests validate configuration security and scan for vulnerabilities.

### Security Test Categories

1. **Vulnerability Scanning**:
   ```bash
   make test-security-trivy
   ```

2. **Policy Validation**:
   ```bash
   make test-security-checkov
   make test-security-terrascan
   ```

3. **Secret Detection**:
   ```bash
   make test-security-secrets
   ```

### Security Test Configuration

Configure security tools in `.trivyignore`, `.checkov.yml`, etc.:

```yaml
# .checkov.yml
framework:
  - terraform
  - kubernetes
  - helm

skip-check:
  - CKV_K8S_8  # Resource limits (handled by variables)
  - CKV_K8S_10 # runAsNonRoot (service-specific)
```

## 🔄 CI/CD Testing

Automated testing in CI/CD pipelines.

### GitHub Actions Integration

The project includes comprehensive CI testing:

```yaml
# .github/workflows/ci-consolidated.yml
- name: Test Makefile Commands
  run: |
    make test-safe
    make docs
    make help
```

### Local CI Simulation

```bash
# Simulate CI environment
export CI=true

# Run CI-specific tests
make ci-test-fast           # Quick CI tests
make ci-test-comprehensive  # Full CI suite
make ci-security           # Security scanning
```

## 📊 Test Reporting

### Generate Test Reports

```bash
# Generate comprehensive test report
make test-report

# Generate coverage report
make test-coverage

# CI-specific reporting
make ci-report
```

### Test Artifacts

Tests generate various artifacts:

- `integration-test-*.log` - Integration test logs
- `performance-test-*.json` - Performance test results
- `security-scan-*.sarif` - Security scan results
- `test-results-*.xml` - JUnit-style test results

### Cleanup Test Artifacts

```bash
# Clean up test files
make test-cleanup

# Clean all temporary files
make clean
```

## 🐛 Debugging Test Failures

### Common Issues and Solutions

1. **Terraform Validation Errors**:
   ```bash
   # Reinitialize Terraform
   rm -rf .terraform .terraform.lock.hcl
   make init
   ```

2. **Test File Not Found**:
   ```bash
   # Check test file exists
   ls -la tests*.tftest.hcl test-scenarios.tftest.hcl

   # Create missing test file
   touch tests.tftest.hcl
   ```

3. **Module Dependencies**:
   ```bash
   # Update module dependencies
   terraform get -update
   terraform init -upgrade
   ```

4. **Pre-commit Hook Failures**:
   ```bash
   # Update hooks
   pre-commit autoupdate

   # Run specific hook
   pre-commit run terraform-fmt --all-files
   ```

### Debug Commands

```bash
# Debug CI environment
make ci-debug

# Show tool versions
make version

# Environment detection
make detect-environment

# Troubleshooting guide
make troubleshoot
```

## 📈 Test Development Best Practices

### 1. Test Naming Conventions

```hcl
# Good test names
run "test_arm64_resource_limits" { }
run "test_nfs_storage_configuration" { }
run "test_mixed_cluster_scheduling" { }

# Avoid generic names
run "test1" { }
run "basic_test" { }
```

### 2. Test Organization

```hcl
# Group related tests
run "test_prometheus_enabled" { }
run "test_prometheus_disabled" { }
run "test_prometheus_arm64_limits" { }

# Separate concerns
run "test_storage_nfs" { }
run "test_storage_hostpath" { }
run "test_storage_cloud" { }
```

### 3. Assertion Best Practices

```hcl
# Specific assertions
assert {
  condition = local.prometheus_cpu_limit == "200m"
  error_message = "Expected ARM64 CPU limit to be 200m, got ${local.prometheus_cpu_limit}"
}

# Avoid vague assertions
assert {
  condition = local.config != null
  error_message = "Config is null"
}
```

### 4. Test Data Management

```hcl
# Use variables for test data
variables {
  test_scenarios = {
    raspberry_pi = {
      cpu_arch = "arm64"
      storage  = "hostpath"
    }
    cloud = {
      cpu_arch = "amd64"
      storage  = "ebs"
    }
  }
}
```

## 🎯 Testing Checklist

Before submitting a PR, ensure:

- [ ] All static analysis passes (`make test-lint`)
- [ ] Unit tests pass (`make test-unit`)
- [ ] Scenario tests pass (`make test-scenarios`)
- [ ] Documentation is updated (`make docs`)
- [ ] Pre-commit hooks are installed and passing
- [ ] New features have corresponding tests
- [ ] Security scans pass (`make test-security`)
- [ ] Integration tests pass (if infrastructure is deployed)

## 📚 Additional Resources

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [k6 Performance Testing](https://k6.io/docs/)
- [Checkov Policy Reference](https://www.checkov.io/5.Policy%20Index/terraform.html)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)
- [Pre-commit Hooks](https://pre-commit.com/)

---

**Happy Testing!** 🧪 Remember: good tests make for reliable infrastructure and confident deployments.
