# Terraform Module

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.disallow_privileged_constraint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.disallow_privileged_template](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.pvc_size_limit_constraint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.pvc_size_limit_template](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.require_resources_constraint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.require_resources_template](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.require_security_context_constraint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.require_security_context_template](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_hostpath_policy"></a> [enable\_hostpath\_policy](#input\_enable\_hostpath\_policy) | Enable hostpath PVC size limit policy | `bool` | `true` | no |
| <a name="input_enable_resource_policies"></a> [enable\_resource\_policies](#input\_enable\_resource\_policies) | Enable resource requirement policies (CPU/memory limits) | `bool` | `true` | no |
| <a name="input_enable_security_policies"></a> [enable\_security\_policies](#input\_enable\_security\_policies) | Enable security-related policies (security context, privileged containers) | `bool` | `true` | no |
| <a name="input_hostpath_max_size"></a> [hostpath\_max\_size](#input\_hostpath\_max\_size) | Maximum allowed size for hostpath PVCs | `string` | `"10Gi"` | no |
| <a name="input_hostpath_storage_class"></a> [hostpath\_storage\_class](#input\_hostpath\_storage\_class) | Storage class name for hostpath policy | `string` | `"hostpath"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"gatekeeper-stack"` | no |

## Outputs

No outputs.

<!-- END_TF_DOCS -->
