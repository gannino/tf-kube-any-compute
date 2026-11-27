# Kubernetes provider configuration
#
# Cluster selection via terraform workspaces + var.kubeconfig_path:
#   terraform workspace select on-prem   # uses terraform.on-prem.tfvars
#   terraform workspace select on-cloud  # uses terraform.on-cloud.tfvars
#
# kubeconfig resolution order:
#   1. var.kubeconfig_path (explicit override in tfvars)
#   2. ~/.kube/<workspace_prefix>-config  (workspace-based detection)
#   3. ~/.kube/config                       (default)
#
# Context inside that file: var.kubeconfig_context, set per cluster in the
# tfvars file. Empty = the kubeconfig's current context.
provider "kubernetes" {
  config_path = local.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path :
    can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
    "~/.kube/config"
  )
  config_context = local.ci_mode || var.kubeconfig_context == "" ? null : var.kubeconfig_context
}

provider "helm" {
  kubernetes = {
    config_path = local.ci_mode ? null : (
      var.kubeconfig_path != "" ? var.kubeconfig_path :
      can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
      "~/.kube/config"
    )
    config_context = local.ci_mode || var.kubeconfig_context == "" ? null : var.kubeconfig_context
  }
}

# Configure the kubectl provider (same config as your kubernetes provider)
provider "kubectl" {
  config_path = local.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path :
    can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
    "~/.kube/config"
  )
  config_context = local.ci_mode || var.kubeconfig_context == "" ? null : var.kubeconfig_context
}

# data "terraform_remote_state" "sit_infrastructure" {
#   count   = terraform.workspace == "sit" ? 1 : 0
#   backend = "s3"
#   config = {
#     bucket  = "default-tf-s3-state-prod-eu"
#     region  = "eu-central-1"
#     key     = "kube-infra/build/terraform.tfstate"
#     profile = "default"
#   }
# }


# terraform {
#   backend "s3" {
#     profile              = "default"
#     encrypt              = true
#     bucket               = "default-tf-s3-state-prod-eu"
#     dynamodb_table       = "default-tf-s3-state-prod-eu"
#     region               = "eu-central-1"
#     key                  = "terraform.tfstate"
#     workspace_key_prefix = "kube-infra"
#   }
# }
