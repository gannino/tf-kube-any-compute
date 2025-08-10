# Kubernetes provider configuration with CI mode support
provider "kubernetes" {
  # In CI mode, use default kubeconfig or skip if not available
  config_path = can(file("~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config")) ? "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config" : "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = can(file("~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config")) ? "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config" : "~/.kube/config"
  }
}

# Configure the kubectl provider (same config as your kubernetes provider)
provider "kubectl" {
  config_path = can(file("~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config")) ? "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config" : "~/.kube/config"
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
#     dynamodb_table       = "default-tf-dyn-lock-prod-eu"
#     region               = "eu-central-1"
#     key                  = "terraform.tfstate"
#     workspace_key_prefix = "kube-infra"
#   }
# }
