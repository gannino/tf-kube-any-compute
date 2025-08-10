provider "kubernetes" {
  config_path = "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config"
  #config_context = lookup(local.context. terraform.workspace)
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config"
  }
}

# Configure the kubectl provider (same config as your kubernetes provider)
provider "kubectl" {
  config_path = "~/.kube/${lower(try(local.workspace[terraform.workspace], terraform.workspace))}-config"
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
