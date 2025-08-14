# Cloud Provider Configuration
# Optimized for EKS/GKE/AKS deployments

base_domain   = "cloud.example.com"
platform_name = "k8s"
cpu_arch      = "amd64"

# Cloud-native service stack
services = {
  traefik                = true
  metallb                = false # Use cloud load balancer
  host_path              = false
  nfs_csi                = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  loki                   = true
  promtail               = true
  consul                 = true
  vault                  = true
  gatekeeper             = true
  portainer              = true
  node_feature_discovery = true
}

# Cloud storage
use_nfs_storage      = true
use_hostpath_storage = false
nfs_server_address   = "nfs.cloud.internal"
nfs_server_path      = "/shared/k8s"

# Production resource limits
enable_resource_limits = true
default_cpu_limit      = "2000m"
default_memory_limit   = "4Gi"

# SSL configuration - uses DNS provider name automatically
# traefik_cert_resolver = "route53"  # AWS Route53 for cloud deployment
le_email = "admin@example.com"

# Cloud-optimized overrides
service_overrides = {
  # Disable dashboard for CI compatibility
  traefik = {
    enable_dashboard = false

    # Cloud DNS provider configuration (example for AWS)
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          # AWS_ACCESS_KEY_ID = "your-access-key"
          # AWS_SECRET_ACCESS_KEY = "your-secret-key"
          # AWS_REGION = "us-east-1"
        }
      }
    }

    cert_resolvers = {
      default = {
        challenge_type = "http"
      }
      route53 = {
        challenge_type = "dns"
        dns_provider   = "route53"
      }
    }
  }

  # No MetalLB needed in cloud
  metallb = {
    address_pool = ""
  }

  # High-performance monitoring
  prometheus = {
    storage_size = "50Gi"
    cpu_limit    = "2000m"
    memory_limit = "8Gi"
  }

  # Secure vault configuration
  vault = {
    helm_timeout = 900
    storage_size = "10Gi"
  }
}
