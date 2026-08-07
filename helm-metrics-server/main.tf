resource "helm_release" "this" {
  name       = var.name
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    yamlencode({
      # Only pass args NOT already injected by the chart's defaultArgs template.
      # Chart v3.13.0 already provides: --cert-dir, --secure-port,
      # --kubelet-preferred-address-types, --kubelet-use-node-status-port, --metric-resolution.
      # Passing them again produced duplicate flags in the container args.
      args = concat([
        "--kubelet-insecure-tls"
      ], var.enable_microk8s_mode ? ["--authorization-always-allow-paths=/livez,/readyz"] : [])

      service = {
        port = var.service_port
      }

      resources = var.enable_resource_limits ? {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
      } : {}

      nodeSelector = !var.disable_arch_scheduling && var.cpu_arch != "" ? {
        "kubernetes.io/arch" = var.cpu_arch
      } : {}

      # Chart default probe timeout is 1s, too aggressive for ARM64/Pi TLS handshake.
      # Without this override metrics-server gets killed into CrashLoopBackOff.
      livenessProbe = {
        timeoutSeconds   = var.probe_timeout_seconds
        failureThreshold = var.probe_failure_threshold
      }

      readinessProbe = {
        timeoutSeconds   = var.probe_timeout_seconds
        failureThreshold = var.probe_failure_threshold
      }
    })
  ]

  timeout          = var.helm_timeout
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs
  atomic           = var.helm_atomic
  cleanup_on_fail  = var.helm_cleanup_on_fail
  force_update     = var.helm_force_update
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace

  create_namespace = false

  depends_on = [kubernetes_namespace.this]
}
