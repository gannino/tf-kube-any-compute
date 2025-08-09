# Grafana Configuration
serviceAccount:
  name: ${GRAFANA_SERVICE_ACCOUNT}
  create: true

# Admin user configuration
adminUser: ${GRAFANA_ADMIN_USER}
adminPassword: ${GRAFANA_ADMIN_PASSWORD}

# Grafana configuration
grafana.ini:
  security:
    admin_user: ${GRAFANA_ADMIN_USER}

# Persistence
persistence:
  enabled: ${ENABLE_PERSISTENCE}
  size: ${STORAGE_SIZE}
  storageClassName: "${STORAGE_CLASS}"
initChownData:
  enabled: true
extraInitContainers: []

# Service configuration
service:
  type: ClusterIP
  port: 80

# Ingress disabled - using separate traefik-ingress.tf
ingress:
  enabled: false

# Resources
resources:
  limits:
    cpu: ${CPU_LIMIT}
    memory: ${MEMORY_LIMIT}
  requests:
    cpu: ${CPU_REQUEST}
    memory: ${MEMORY_REQUEST}

# Datasources configuration
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: ${PROMETHEUS_URL}
      access: proxy
      isDefault: true
    - name: Alertmanager
      type: alertmanager
      url: ${ALERTMANAGER_URL}
      access: proxy
      jsonData:
        implementation: prometheus
    - name: Loki
      type: loki
      url: ${LOKI_URL}
      access: proxy

# Dashboard providers
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

# Default dashboards
dashboards:
  default:
    # Core Kubernetes dashboards from kube-prometheus-stack
    k8s-cluster-total:
      gnetId: 15757
      revision: 1
      datasource: Prometheus
    k8s-resources-cluster:
      gnetId: 15758
      revision: 1
      datasource: Prometheus
    k8s-resources-multicluster:
      gnetId: 15759
      revision: 1
      datasource: Prometheus
    kubernetes-cluster-monitoring:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    k8s-resources-namespace:
      gnetId: 15759
      revision: 1
      datasource: Prometheus
    k8s-resources-node:
      gnetId: 15760
      revision: 1
      datasource: Prometheus
    k8s-resources-pod:
      gnetId: 15761
      revision: 1
      datasource: Prometheus
    k8s-resources-workload:
      gnetId: 15762
      revision: 1
      datasource: Prometheus
    k8s-resources-workloads-namespace:
      gnetId: 15763
      revision: 1
      datasource: Prometheus
    # Node monitoring
    node-exporter:
      gnetId: 1860
      revision: 31
      datasource: Prometheus
    node-rsrc-use:
      gnetId: 15763
      revision: 1
      datasource: Prometheus
    # Kubernetes components
    apiserver:
      gnetId: 15761
      revision: 1
      datasource: Prometheus
    kubelet:
      gnetId: 15764
      revision: 1
      datasource: Prometheus
    k8s-coredns:
      gnetId: 15762
      revision: 1
      datasource: Prometheus
    # Monitoring stack
    prometheus-stats:
      gnetId: 2
      revision: 2
      datasource: Prometheus
    alertmanager-overview:
      gnetId: 9578
      revision: 4
      datasource: Prometheus
    grafana-overview:
      gnetId: 3590
      revision: 3
      datasource: Prometheus
    # Application monitoring
    traefik:
      gnetId: 4475
      revision: 5
      datasource: Prometheus

# Security context
securityContext:
  runAsGroup: 1002
  fsGroup: 1002

# Node selector for architecture and hostname
%{ if GRAFANA_NODE_NAME != "" ~}
nodeName: ${GRAFANA_NODE_NAME}
%{ else ~}
%{ if CPU_ARCH != "" ~}
nodeSelector:
  kubernetes.io/arch: ${CPU_ARCH}
%{ endif ~}
%{ endif ~}

# Additional environment variables
env:
  GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER}
  GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
  GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION: "false"

# RBAC settings to address ClusterRole error
rbac:
  create: true
  pspEnabled: false
  namespaced: true

livenessProbe:
  httpGet:
    path: /api/health
    port: 3000
  initialDelaySeconds: 180
  timeoutSeconds: 60
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 10
readinessProbe:
  httpGet:
    path: /api/health
    port: 3000
  initialDelaySeconds: 30
  timeoutSeconds: 10
