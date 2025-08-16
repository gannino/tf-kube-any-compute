locals {
  consul_values = templatefile("${path.module}/templates/consul-values.yaml.tpl", {
    name                     = var.name
    namespace                = var.namespace
    persistent_disk_size     = var.persistent_disk_size
    storage_class            = var.storage_class
    consul_image_version     = var.consul_image_version
    consul_k8s_image_version = var.consul_k8s_image_version
    cpu_limit                = var.cpu_limit
    memory_limit             = var.memory_limit
    cpu_request              = var.cpu_request
    memory_request           = var.memory_request
    server_replicas          = var.server_replicas
    client_replicas          = var.client_replicas
  })
}
