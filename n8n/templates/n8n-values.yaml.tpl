# ============================================================================
# N8N HELM VALUES TEMPLATE - ABSOLUTE MINIMAL
# ============================================================================

%{ if length(node_selector) > 0 ~}
nodeSelector:
%{ for key, value in node_selector ~}
  ${key}: ${value}
%{ endfor ~}
%{ endif ~}

main:
  persistence:
%{ if enable_persistence ~}
    enabled: true
    existingClaim: "${name}-data"
%{ else ~}
    enabled: false
%{ endif ~}

license:
  enabled: false

ingress:
  enabled: false
