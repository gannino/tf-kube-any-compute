provider "kubernetes" {
  config_path = local.ci_mode ? null : "~/.kube/${local.workspace_prefix}-config"
  # In CI mode, rely on in-cluster config or skip cluster access for plan validation
}

provider "helm" {
  kubernetes = {
    config_path = local.ci_mode ? null : "~/.kube/${local.workspace_prefix}-config"
  }
}

# Configure the kubectl provider (same config as your kubernetes provider)
provider "kubectl" {
  config_path = local.ci_mode ? null : "~/.kube/${local.workspace_prefix}-config"
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
