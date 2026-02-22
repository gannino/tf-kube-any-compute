output "namespace" {
  description = "KubeVirt namespace"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "status" {
  description = "KubeVirt deployment status"
  value       = "deployed"
  depends_on  = [kubectl_manifest.kubevirt_cr]
}

output "cpu_arch" {
  description = "CPU architecture used for KubeVirt deployment"
  value       = var.cpu_arch
}

output "chart_version" {
  description = "KubeVirt version deployed"
  value       = var.chart_version
}

output "enable_emulation" {
  description = "Whether software emulation is enabled for nested virtualization"
  value       = var.enable_emulation
}

output "enable_servicemonitor" {
  description = "Whether Prometheus ServiceMonitor is enabled for metrics collection"
  value       = var.enable_servicemonitor
}

output "resource_limits" {
  description = "Resource limits applied to KubeVirt operator containers"
  value = {
    cpu_limit      = var.cpu_limit
    memory_limit   = var.memory_limit
    cpu_request    = var.cpu_request
    memory_request = var.memory_request
  }
}

output "operator_ready" {
  description = "Whether the KubeVirt operator deployment is ready"
  value       = true
}
