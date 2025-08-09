# Create metallb namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.module_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Deploy MetalLB via Helm
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [local.metallb_values]

  # Helm configuration from locals
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Default IP Address Pool
resource "kubectl_manifest" "metallb_ip_pool" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default-pool
      namespace: ${kubernetes_namespace.this.metadata[0].name}
      labels:
        app.kubernetes.io/name: metallb
        app.kubernetes.io/component: load-balancer
    spec:
      addresses:
      - ${local.module_config.address_pool}
      autoAssign: true
  YAML

  depends_on = [helm_release.this]
}

# L2 Advertisement (only when BGP is disabled)
resource "kubectl_manifest" "metallb_l2_advert" {
  count = var.enable_bgp ? 0 : 1

  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: l2
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      ipAddressPools:
      - default-pool
  YAML

  depends_on = [helm_release.this]
}

# BGP Peers (only when BGP is enabled)
resource "kubectl_manifest" "metallb_bgp_peers" {
  for_each = var.enable_bgp ? { for idx, peer in var.bgp_peers : idx => peer } : {}

  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta2
    kind: BGPPeer
    metadata:
      name: bgp-peer-${each.key}
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      myASN: ${each.value.my_asn}
      peerASN: ${each.value.peer_asn}
      peerAddress: ${each.value.peer_address}
  YAML

  depends_on = [helm_release.this]
}

# BGP Advertisement (only when BGP is enabled)
resource "kubectl_manifest" "metallb_bgp_advert" {
  count = var.enable_bgp ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: BGPAdvertisement
    metadata:
      name: bgp
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      ipAddressPools:
      - default-pool
  YAML

  depends_on = [helm_release.this]
}

# Additional IP Address Pools
resource "kubectl_manifest" "metallb_additional_pools" {
  for_each = { for pool in var.additional_ip_pools : pool.name => pool }

  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: ${each.value.name}
      namespace: ${kubernetes_namespace.this.metadata[0].name}
    spec:
      addresses:
%{for address in each.value.addresses~}
      - ${address}
%{endfor~}
      autoAssign: ${each.value.auto_assign}
  YAML

  depends_on = [helm_release.this]
}
