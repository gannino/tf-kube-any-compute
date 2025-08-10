# Cloud deployment test configuration
base_domain   = "cloud.example.com"
platform_name = "cloud"
cpu_arch      = "amd64"

services = {
  traefik                = true
  metallb                = false # Use cloud load balancer
  host_path              = false
  prometheus             = true
  grafana                = true
  consul                 = true
  vault                  = true
  gatekeeper             = true
  portainer              = true
  loki                   = true
  promtail               = true
  nfs_csi                = true
  node_feature_discovery = true
  prometheus_crds        = true
}

use_hostpath_storage = false
use_nfs_storage      = true
nfs_server_address   = "nfs.cloud.internal"
nfs_server_path      = "/shared/k8s"

enable_microk8s_mode   = false
enable_resource_limits = true
default_cpu_limit      = "2000m"
default_memory_limit   = "4Gi"

traefik_cert_resolver = "letsencrypt"
