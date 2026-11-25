# Kubernetes provider configuration
#
# Cluster selection via terraform workspaces + var.kubeconfig_path:
#   terraform workspace select on-prem   # uses terraform.tfvars.on-prem
#   terraform workspace select on-cloud  # uses terraform.tfvars.on-cloud
#
# kubeconfig resolution order:
#   1. var.kubeconfig_path (explicit override in tfvars)
#   2. ~/.kube/<workspace_prefix>-config  (workspace-based detection)
#   3. ~/.kube/config                       (default)
provider "kubernetes" {
  config_path = local.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path :
    can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
    "~/.kube/config"
  )
}

provider "helm" {
  kubernetes = {
    config_path = local.ci_mode ? null : (
      var.kubeconfig_path != "" ? var.kubeconfig_path :
      can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
      "~/.kube/config"
    )
  }
}

# Configure the kubectl provider (same config as your kubernetes provider)
provider "kubectl" {
  config_path = local.ci_mode ? null : (
    var.kubeconfig_path != "" ? var.kubeconfig_path :
    can(file("~/.kube/${local.workspace_prefix}-config")) ? "~/.kube/${local.workspace_prefix}-config" :
    "~/.kube/config"
  )
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
