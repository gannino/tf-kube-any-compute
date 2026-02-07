# ============================================================================
# KUBEVIRT EXAMPLE CONFIGURATION
# ============================================================================
# This example shows how to enable and configure KubeVirt for virtual machine
# management in your Kubernetes cluster.

# Basic domain configuration
base_domain   = "example.com"
platform_name = "k3s"
le_email      = "admin@example.com"

# Enable KubeVirt service
services = {
  kubevirt = true

  # Core services
  traefik                = true
  metallb                = true
  nfs_csi                = true
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  kube_state_metrics     = true
  node_feature_discovery = true
}

# KubeVirt configuration
service_overrides = {
  kubevirt = {
    # Architecture - AMD64 recommended for best performance
    cpu_arch = "amd64"

    # Enable software emulation for ARM64 or nested virtualization
    enable_emulation = true

    # Enable Prometheus monitoring
    enable_servicemonitor = true

    # Resource limits - adjust based on your cluster capacity
    cpu_limit      = "2000m" # 2 CPU cores
    memory_limit   = "4Gi"   # 4GB RAM
    cpu_request    = "1000m" # 1 CPU core
    memory_request = "2Gi"   # 2GB RAM

    # Helm deployment options
    helm_timeout = 900 # 15 minutes for initial deployment
  }
}

# Storage configuration - KubeVirt VMs need persistent storage
use_nfs_storage    = true
nfs_server_address = "192.168.1.100"
nfs_server_path    = "/mnt/k8s-storage"

# MetalLB for VM external access
metallb_address_pool = "192.168.1.200-192.168.1.210"

# ============================================================================
# EXAMPLE VIRTUAL MACHINE DEPLOYMENT
# ============================================================================
# After deploying KubeVirt, you can create VMs using kubectl:
#
# kubectl apply -f - <<EOF
# apiVersion: kubevirt.io/v1
# kind: VirtualMachine
# metadata:
#   name: testvm
#   namespace: default
# spec:
#   running: true
#   template:
#     metadata:
#       labels:
#         kubevirt.io/vm: testvm
#     spec:
#       domain:
#         devices:
#           disks:
#           - name: containerdisk
#             disk:
#               bus: virtio
#           - name: cloudinitdisk
#             disk:
#               bus: virtio
#         resources:
#           requests:
#             memory: 1024M
#             cpu: 1
#       volumes:
#       - name: containerdisk
#         containerDisk:
#           image: quay.io/kubevirt/cirros-container-disk-demo
#       - name: cloudinitdisk
#         cloudInitNoCloud:
#           userDataBase64: SGkuXG4=
# EOF
#
# # Check VM status
# kubectl get vms
# kubectl get vmis
#
# # Access VM console
# virtctl console testvm
