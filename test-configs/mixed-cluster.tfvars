# Mixed cluster test configuration
base_domain             = "mixed.local"
platform_name           = "mixed"
cpu_arch                = ""
auto_mixed_cluster_mode = true

services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  grafana                = true
  consul                 = true
  vault                  = true
  gatekeeper             = false
  portainer              = true
  loki                   = true
  promtail               = true
  nfs_csi                = true
  node_feature_discovery = true
  prometheus_crds        = true
}

cpu_arch_override = {
  traefik          = "amd64"
  prometheus_stack = "amd64"
  vault            = "amd64"
  grafana          = "arm64"
  portainer        = "arm64"
}

use_hostpath_storage = true
use_nfs_storage      = true
nfs_server_address   = "192.168.1.100"
nfs_server_path      = "/mnt/k8s"

enable_resource_limits = true
default_cpu_limit      = "1000m"
default_memory_limit   = "1Gi"

metallb_address_pool = "192.168.1.220-192.168.1.230"
