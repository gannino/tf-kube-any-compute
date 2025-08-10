# Install only CRDs from kube-prometheus-stack
crds:
  enabled: true

# Disable all other components - we only want CRDs
prometheusOperator:
  enabled: false
prometheus:
  enabled: false
alertmanager:
  enabled: false
grafana:
  enabled: false
kubeApiServer:
  enabled: false
kubelet:
  enabled: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: false
kubeStateMetrics:
  enabled: false
nodeExporter:
  enabled: false
