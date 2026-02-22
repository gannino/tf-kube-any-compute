# MetalLB Module

A Terraform module for deploying MetalLB on Kubernetes using Helm. MetalLB provides a network load balancer implementation for Kubernetes clusters that don't run on a supported cloud provider, allowing you to create LoadBalancer services without an external cloud provider.

## Features

- **🚀 Bare-Metal Load Balancing**: Provides LoadBalancer services for bare-metal clusters
- **🔌 Layer 2 Mode**: Simple ARP/NDP-based load balancing for local networks
- **📡 BGP Mode**: Advanced BGP-based load balancing for production networks
- **🏗️ Multi-Architecture Support**: ARM64 and AMD64 with auto-detection
- **📊 Prometheus Integration**: Optional metrics and monitoring
- **⚡ Lightweight**: Minimal resource footprint

## Requirements

| Name | Version |
|------|----------|
| Terraform | >= 0.14 |
| Helm Provider | ~> 3.0 |
| Kubectl Provider | ~> 1.14 |
| Kubernetes Provider | ~> 2.0 |

## Usage

### Basic Deployment

```hcl
module "metallb" {
  source = "./helm-metallb"

  namespace    = "metallb-system"
  address_pool = "192.168.1.200-192.168.1.210"
}
```

### With Resource Limits

```hcl
module "metallb" {
  source = "./helm-metallb"

  namespace      = "metallb-system"
  address_pool   = "192.168.1.200-192.168.1.210"
  cpu_limit      = "100m"
  memory_limit   = "64Mi"
}
```

### ARM64 Deployment

```hcl
module "metallb" {
  source = "./helm-metallb"

  namespace    = "metallb-system"
  address_pool = "192.168.1.200-192.168.1.210"
  cpu_arch     = "arm64"
}
```

## Module Integration

### Using Module Outputs (Recommended)

MetalLB provides IP address pool information for services that need LoadBalancer IPs:

```hcl
module "metallb" {
  source = "./helm-metallb"
  address_pool = "192.168.1.200-192.168.1.210"
}

# Reference the IP pool for documentation or other modules
output "loadbalancer_ip_range" {
  value = module.metallb.ip_address_pool
}
```

### Configuring LoadBalancer Services

Services that need external IPs can use MetalLB by setting type: LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: my-app
```

MetalLB will automatically assign an IP from the configured address pool.

## Architecture Support

| Architecture | Status | Notes |
|--------------|--------|-------|
| AMD64 (x86_64) | ✅ Fully Supported | Standard for most servers |
| ARM64 | ✅ Fully Supported | Raspberry Pi, ARM servers |
| Mixed Clusters | ✅ Supported | Use `disable_arch_scheduling` for cluster-wide deployment |

### Resource Recommendations

**Development/Lab**:
- CPU: 25m - 100m
- Memory: 32Mi - 64Mi

**Production**:
- CPU: 100m - 200m
- Memory: 64Mi - 128Mi

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `namespace` | Kubernetes namespace for MetalLB | `string` | `"metallb-system"` | no |
| `address_pool` | IP address pool for LoadBalancer services | `string` | `"192.168.169.30-192.168.169.60"` | no |
| `cpu_arch` | CPU architecture for node selection | `string` | `"arm64"` | no |
| `disable_arch_scheduling` | Disable architecture-based scheduling | `bool` | `false` | no |
| `cpu_limit` | CPU limit for containers | `string` | `"100m"` | no |
| `memory_limit` | Memory limit for containers | `string` | `"64Mi"` | no |
| `helm_timeout` | Helm deployment timeout in seconds | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Kubernetes namespace where MetalLB is deployed |
| `name` | Name of the MetalLB deployment |
| `ip_address_pool` | IP address pool configured for LoadBalancer services |
| `helm_release` | Helm release name for MetalLB |
| `chart_version` | Helm chart version deployed |

## Troubleshooting

### MetalLB Pod Not Starting

**Problem**: Pods in CrashLoopBackOff state

**Solutions**:
1. Check logs: `kubectl logs -n metallb-system deployment/metallb-controller`
2. Verify RBAC: `kubectl get clusterrole,clusterrolebinding | grep metallb`
3. Check resource limits: `kubectl describe pod -n metallb-system`

### No IP Assigned to LoadBalancer Service

**Problem**: Service pending with no external IP

**Solutions**:
1. Verify IP pool configuration: `kubectl get ipaddresspool -n metallb-system`
2. Check L2 advertisement: `kubectl get l2advertisement -n metallb-system`
3. Ensure service type is LoadBalancer: `kubectl get svc <service-name> -o yaml`

### IP Address Conflicts

**Problem**: Duplicate IPs on the network

**Solutions**:
1. Ensure IP pool doesn't overlap with DHCP range
2. Use IP reservation on your router
3. Check for duplicate IP assignments: `arp -a`

### Common Issues

1. **Speaker Not Running**
   - Symptom: Layer 2 announcements not working
   - Fix: Ensure speaker DaemonSet is deployed on all nodes

2. **Controller Not Running**
   - Symptom: IP assignment not working
   - Fix: Check controller logs and RBAC permissions

3. **BGP Session Not Established**
   - Symptom: BGP mode not working
   - Fix: Verify BGP peer configuration and network connectivity

## Maintenance

### Upgrading MetalLB

```bash
# Check current version
helm list -n metallb-system

# Upgrade to new version (update chart_version in variables)
terraform plan
terraform apply
```

### Changing IP Pool

Update the `address_pool` variable and apply:

```hcl
module "metallb" {
  source = "./helm-metallb"
  address_pool = "10.0.0.100-10.0.0.150"  # New range
}
```

**Note**: Existing LoadBalancer services will retain their IPs until the service is recreated.

## Additional Resources

- [MetalLB Official Documentation](https://metallb.universe.tf/)
- [Layer 2 Mode Guide](https://metallb.universe.tf/installation/)
- [BGP Configuration](https://metallb.universe.tf/configuration/)
- [tf-kube-any-compute Documentation](../../README.md)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.metallb_ip_pool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metallb_l2_advert](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_pool"></a> [address\_pool](#input\_address\_pool) | MetalLB address pool | `string` | `"192.168.169.30-192.168.169.60"` | no |
| <a name="input_controller_replica_count"></a> [controller\_replica\_count](#input\_controller\_replica\_count) | Number of replicas for the controller | `number` | `1` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable ingress | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_gateway_chart_name"></a> [ingress\_gateway\_chart\_name](#input\_ingress\_gateway\_chart\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_ingress_gateway_chart_repo"></a> [ingress\_gateway\_chart\_repo](#input\_ingress\_gateway\_chart\_repo) | Ingress Gateway Helm repository name. | `string` | `"https://metallb.github.io/metallb"` | no |
| <a name="input_ingress_gateway_chart_version"></a> [ingress\_gateway\_chart\_version](#input\_ingress\_gateway\_chart\_version) | Ingress Gateway Helm repository version. | `string` | `"0.13.10"` | no |
| <a name="input_ingress_gateway_name"></a> [ingress\_gateway\_name](#input\_ingress\_gateway\_name) | Ingress Gateway Helm chart name. | `string` | `"metallb"` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Let's Encrypt email | `string` | `""` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Ingress Gateway namespace. | `string` | `"metallb-system"` | no |
| <a name="input_persistent_disc_size"></a> [persistent\_disc\_size](#input\_persistent\_disc\_size) | Persistent disk size | `string` | `"1"` | no |
| <a name="input_speaker_replica_count"></a> [speaker\_replica\_count](#input\_speaker\_replica\_count) | Number of replicas for the speaker | `number` | `1` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Workspace name | `string` | `"set-me"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release name for MetalLB |
| <a name="output_ip_address_pool"></a> [ip\_address\_pool](#output\_ip\_address\_pool) | IP address pool configured for MetalLB LoadBalancer services |
| <a name="output_ip_address_pool_name"></a> [ip\_address\_pool\_name](#output\_ip\_address\_pool\_name) | Name of the IPAddressPool resource |
| <a name="output_name"></a> [name](#output\_name) | Name of the MetalLB deployment |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace where MetalLB is deployed |
<!-- END_TF_DOCS -->
