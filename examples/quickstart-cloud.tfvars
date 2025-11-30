# ============================================================================
# QUICK START: Cloud Deployment (EKS/GKE/AKS)
# ============================================================================
# Configuration for cloud Kubernetes services
# Copy to terraform.tfvars and customize
# ============================================================================

# Basic Settings
base_domain   = "example.com"
platform_name = "eks" # or "gke", "aks"
le_email      = "admin@example.com"

# Cloud - No MetalLB needed
use_nfs_storage      = false
use_hostpath_storage = false

# Full Production Stack
services = {
  traefik                = true
  metallb                = false # Cloud LB
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  kube_state_metrics     = true
  loki                   = true
  promtail               = true
  consul                 = true
  vault                  = true
  gatekeeper             = true
  portainer              = true
  node_feature_discovery = true
}

# Cloud DNS Provider (AWS Route53 example)
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          AWS_ACCESS_KEY_ID     = "your-access-key"
          AWS_SECRET_ACCESS_KEY = "your-secret-key"
          AWS_REGION            = "us-east-1"
        }
      }
    }
  }

  prometheus = {
    storage_size = "50Gi"
    cpu_limit    = "2000m"
    memory_limit = "4Gi"
  }
}

# STEP 2: Enable authentication after first deployment
middleware_overrides = {
  enabled = false # Change to true after first deployment
}
