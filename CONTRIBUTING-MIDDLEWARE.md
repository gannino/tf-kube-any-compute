# Contributing to the Middleware System

## Quick Start for Contributors

This guide helps you understand and contribute to the flexible middleware system in tf-kube-any-compute.

## System Overview

The middleware system has two main phases:

1. **Deploy Phase**: Create middleware resources in Kubernetes
2. **Apply Phase**: Assign middlewares to services via ingress annotations

## File Structure

```
├── variables.tf                    # Main middleware configuration variables
├── locals.tf                      # Middleware assignment logic
├── main.tf                        # Service module calls with middleware
├── helm-traefik/
│   ├── middleware/                 # Middleware resource definitions
│   │   ├── main.tf                # Middleware Kubernetes resources
│   │   ├── variables.tf           # Middleware input variables
│   │   └── outputs.tf             # Middleware names for consumption
│   └── main.tf                    # Traefik module with middleware integration
└── helm-prometheus-stack/
    ├── prometheus-ingress.tf      # Prometheus ingress with middleware
    └── alertmanager-ingress.tf    # AlertManager ingress with middleware
```

## Adding a New Middleware

### Step 1: Add Middleware Resource

**File**: `helm-traefik/middleware/main.tf`

```hcl
# Add new middleware resource
resource "kubernetes_manifest" "new_middleware" {
  count = var.new_middleware.enabled ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-new-middleware"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      # Middleware-specific configuration
      newMiddleware = {
        option1 = var.new_middleware.option1
        option2 = var.new_middleware.option2
      }
    }
  }

  depends_on = [var.enable_middleware_resources]
}
```

### Step 2: Add Variables

**File**: `helm-traefik/middleware/variables.tf`

```hcl
variable "new_middleware" {
  description = "New middleware configuration"
  type = object({
    enabled = bool
    option1 = optional(string, "default_value")
    option2 = optional(number, 100)
  })
  default = {
    enabled = false
    option1 = "default_value"
    option2 = 100
  }
}
```

### Step 3: Add Outputs

**File**: `helm-traefik/middleware/outputs.tf`

```hcl
output "new_middleware_name" {
  description = "Name of the new middleware"
  value       = var.new_middleware.enabled ? "${var.name_prefix}-new-middleware" : null
}
```

### Step 4: Update Main Variables

**File**: `variables.tf`

```hcl
# Add to middleware_config structure
middleware_config = optional(object({
  # ... existing middlewares ...

  new_middleware = optional(object({
    enabled = optional(bool, false)
    option1 = optional(string, "default_value")
    option2 = optional(number, 100)
  }), {
    enabled = false
    option1 = "default_value"
    option2 = 100
  })
}))

# Add to middleware_overrides structure
middleware_overrides = {
  all = optional(object({
    # ... existing options ...
    enable_new_middleware = optional(bool, false)
  }))

  # Add to each service
  traefik = optional(object({
    # ... existing options ...
    enable_new_middleware = optional(bool)
  }))
}
```

### Step 5: Update Logic

**File**: `locals.tf`

```hcl
# Add to traefik_middleware_names
traefik_middleware_names = local.services_enabled.traefik ? {
  # ... existing middlewares ...
  new_middleware = module.traefik[0].middleware.new_middleware_name
} : {}

# Add to service_middlewares logic
service_middlewares = {
  for service in concat(local.unprotected_services, local.protected_services) : service => compact(concat(
    # ... existing logic ...

    # New middleware
    coalesce(try(var.middleware_overrides[service].enable_new_middleware, null), try(var.middleware_overrides.all.enable_new_middleware, null), false) && local.traefik_middleware_names.new_middleware != null ? [local.traefik_middleware_names.new_middleware] : [],
  ))
}
```

## Testing Your Changes

### 1. Validate Configuration

```bash
terraform validate
terraform plan
```

### 2. Test Middleware Deployment

```hcl
# terraform.tfvars
service_overrides = {
  traefik = {
    middleware_config = {
      new_middleware = {
        enabled = true
        option1 = "test_value"
        option2 = 200
      }
    }
  }
}
```

### 3. Test Middleware Application

```hcl
# terraform.tfvars
middleware_overrides = {
  traefik = {
    enable_new_middleware = true
  }
}
```

### 4. Verify Deployment

```bash
# Check middleware resource
kubectl get middleware -A | grep new-middleware

# Check ingress annotation
kubectl get ingressroute traefik-dashboard -o yaml | grep middleware

# Test functionality
curl -I https://traefik.your-domain.com
```

## Code Standards

### Variable Naming

- Use `snake_case` for variable names
- Prefix middleware variables with middleware type
- Use descriptive names: `rate_limit_average` not `avg`

### Resource Naming

- Follow pattern: `${var.name_prefix}-{middleware-type}`
- Use kebab-case: `rate-limit` not `rate_limit`
- Keep names short but descriptive

### Documentation

- Add descriptions to all variables
- Include examples in variable descriptions
- Document default values and their reasoning

### Error Handling

```hcl
# Always check if middleware is enabled
count = var.new_middleware.enabled ? 1 : 0

# Use null for disabled middlewares
value = var.new_middleware.enabled ? "${var.name_prefix}-new-middleware" : null

# Validate required fields
validation {
  condition = !var.new_middleware.enabled || var.new_middleware.required_field != ""
  error_message = "Required field must be provided when middleware is enabled."
}
```

## Common Patterns

### Optional Middleware

```hcl
resource "kubernetes_manifest" "optional_middleware" {
  count = var.optional_middleware.enabled ? 1 : 0
  # ... resource definition
}
```

### Conditional Configuration

```hcl
spec = {
  middleware = merge(
    {
      basic_option = var.middleware.basic_option
    },
    var.middleware.advanced_enabled ? {
      advanced_option = var.middleware.advanced_option
    } : {}
  )
}
```

### Service-Specific Logic

```hcl
# Different behavior for different services
middleware_list = service == "traefik" ? [
  "auth-middleware",
  "security-middleware"
] : service == "prometheus" ? [
  "security-middleware"
] : []
```

## Debugging

### Check Middleware Names

```bash
terraform console <<< "local.traefik_middleware_names"
```

### Check Service Assignments

```bash
terraform console <<< "local.service_middlewares.prometheus"
```

### Verify Kubernetes Resources

```bash
kubectl get middleware -A
kubectl describe middleware prod-traefik-new-middleware -n prod-traefik-ingress
```

### Check Ingress Annotations

```bash
kubectl get ingress prod-prometh-alert-prometheus-ingress -o yaml | grep middleware
```

## Pull Request Checklist

- [ ] Added middleware resource in `helm-traefik/middleware/main.tf`
- [ ] Added variables in `helm-traefik/middleware/variables.tf`
- [ ] Added outputs in `helm-traefik/middleware/outputs.tf`
- [ ] Updated main variables in `variables.tf`
- [ ] Updated logic in `locals.tf`
- [ ] Added tests in `test-configs/`
- [ ] Updated documentation
- [ ] Validated with `terraform validate`
- [ ] Tested deployment and functionality
- [ ] Added examples to README or docs

## Examples Repository

Check `test-configs/` directory for complete examples:

- `test-configs/basic-middleware.tfvars` - Basic middleware setup
- `test-configs/advanced-middleware.tfvars` - All middlewares enabled
- `test-configs/selective-middleware.tfvars` - Per-service configuration

## Getting Help

1. **Check existing middlewares** for patterns
2. **Review test configurations** for examples
3. **Use terraform console** for debugging
4. **Test incrementally** - deploy, then apply
5. **Ask questions** in GitHub issues

## Advanced Topics

### Custom Middleware Integration

For middlewares not managed by this system:

```hcl
middleware_overrides = {
  traefik = {
    custom_middlewares = ["external-auth", "custom-headers"]
  }
}
```

### Cross-Service Dependencies

Some middlewares may depend on others:

```hcl
# Ensure auth middleware is applied before rate limiting
middleware_order = [
  local.auth_middleware,
  local.rate_limit_middleware
]
```

### Performance Considerations

- Minimize middleware chains
- Use efficient middleware ordering
- Consider resource usage of complex middlewares
- Test performance impact

Remember: The middleware system is designed to be flexible and extensible. Follow these patterns and your contributions will integrate seamlessly!
