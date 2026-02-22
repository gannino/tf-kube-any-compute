apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubevirt
  namespace: ${namespace}
  labels:
    app.kubernetes.io/name: kubevirt
    app.kubernetes.io/component: monitoring
spec:
  selector:
    matchLabels:
      prometheus.kubevirt.io: ""
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
