# Kube-state-metrics Configuration
# Provides comprehensive Kubernetes cluster metrics for Prometheus

# Image configuration
image:
  registry: registry.k8s.io
  repository: kube-state-metrics/kube-state-metrics
  tag: ""  # Use chart default
  pullPolicy: IfNotPresent

# Service configuration
service:
  type: ClusterIP
  port: 8080
  targetPort: 8080
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"

# ServiceMonitor for Prometheus Operator
prometheus:
  monitor:
    enabled: true
    interval: 30s
    scrapeTimeout: 10s
    honorLabels: true
    additionalLabels:
      app.kubernetes.io/component: kube-state-metrics
      app.kubernetes.io/part-of: infrastructure

# Resources
resources:
  limits:
    cpu: ${CPU_LIMIT}
    memory: ${MEMORY_LIMIT}
  requests:
    cpu: ${CPU_REQUEST}
    memory: ${MEMORY_REQUEST}

# Security context
securityContext:
  enabled: true
  runAsUser: 65534
  runAsGroup: 65534
  fsGroup: 65534
  runAsNonRoot: true

# Pod security context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 65534
  runAsGroup: 65534
  fsGroup: 65534

# RBAC configuration
rbac:
  create: true

# Service account
serviceAccount:
  create: true
  name: ${NAME}
  annotations: {}

# Node selector for architecture
%{ if !DISABLE_ARCH_SCHEDULING && CPU_ARCH != "" ~}
nodeSelector:
  kubernetes.io/arch: ${CPU_ARCH}
%{ endif ~}

# Tolerations for master nodes
tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule

# Affinity rules for high availability
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - kube-state-metrics
        topologyKey: kubernetes.io/hostname

# Collectors configuration - enable comprehensive metrics
collectors:
  - certificatesigningrequests
  - configmaps
  - cronjobs
  - daemonsets
  - deployments
  - endpoints
  - horizontalpodautoscalers
  - ingresses
  - jobs
  - leases
  - limitranges
  - mutatingwebhookconfigurations
  - namespaces
  - networkpolicies
  - nodes
  - persistentvolumeclaims
  - persistentvolumes
  - poddisruptionbudgets
  - pods
  - replicasets
  - replicationcontrollers
  - resourcequotas
  - secrets
  - services
  - statefulsets
  - storageclasses
  - validatingwebhookconfigurations
  - volumeattachments

# Namespace configuration - monitor all namespaces
namespaces: ""

# Metric labels allowlist for better performance
metricLabelsAllowlist:
  - pods=[*]
  - deployments=[*]
  - persistentvolumeclaims=[*]
  - persistentvolumes=[*]
  - nodes=[*]
  - namespaces=[*]

# Metric annotations allowlist
metricAnnotationsAllowList:
  - nodes=[*]
  - pods=[*]

# Self metrics
selfMonitor:
  enabled: true

# Liveness and readiness probes
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

# Pod disruption budget
podDisruptionBudget:
  enabled: true
  minAvailable: 1

# Additional labels
podLabels:
  app.kubernetes.io/component: kube-state-metrics
  app.kubernetes.io/part-of: infrastructure

# Additional annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
