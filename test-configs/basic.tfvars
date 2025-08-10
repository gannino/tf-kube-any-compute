# Basic test configuration
base_domain   = "test.local"
platform_name = "test"
cpu_arch      = ""

services = {
  traefik                = true
  metallb                = true
  host_path              = true
  prometheus             = true
  grafana                = true
  consul                 = false
  vault                  = false
  gatekeeper             = false
  portainer              = false
  loki                   = false
  promtail               = false
  nfs_csi                = false
  node_feature_discovery = true
  prometheus_crds        = true
}

use_hostpath_storage   = true
use_nfs_storage        = false
enable_resource_limits = true
default_cpu_limit      = "500m"
default_memory_limit   = "512Mi"