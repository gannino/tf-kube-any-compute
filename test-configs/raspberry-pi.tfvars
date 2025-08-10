# Raspberry Pi test configuration
base_domain   = "pi.local"
platform_name = "pi"
cpu_arch      = "arm64"

services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  grafana                = true
  consul                 = true
  vault                  = false
  gatekeeper             = false
  portainer              = true
  loki                   = false
  promtail               = false
  nfs_csi                = false
  node_feature_discovery = true
  prometheus_crds        = true
}

use_hostpath_storage   = true
use_nfs_storage        = false
enable_microk8s_mode   = true
enable_resource_limits = true
default_cpu_limit      = "200m"
default_memory_limit   = "256Mi"

metallb_address_pool = "192.168.1.200-192.168.1.210"
