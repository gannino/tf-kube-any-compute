output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "loki_url" {
  value = "http://${var.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:3100"
}
