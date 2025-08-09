# Gatekeeper CRDs Module Version Requirements

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
  }
}
