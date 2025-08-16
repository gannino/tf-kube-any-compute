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

  # Database configuration for better performance
  database:
    type: sqlite3
    path: /var/lib/grafana/grafana.db
    cache_mode: private

  # Query configuration for Kubernetes metrics
  query:
    timeout: 300s
    max_concurrent_queries: 20

  # Dashboard configuration
  dashboards:
    default_home_dashboard_path: /var/lib/grafana/dashboards/default/kubernetes-cluster-monitoring.json

  # Feature toggles
  feature_toggles:
    enable: publicDashboards

  # Logging configuration
  log:
    mode: console
    level: info

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
      jsonData:
        httpMethod: POST
        manageAlerts: true
        prometheusType: Prometheus
        prometheusVersion: 2.40.0
        cacheLevel: 'High'
        disableMetricsLookup: false
        incrementalQuerying: true
    - name: Alertmanager
      type: alertmanager
      url: ${ALERTMANAGER_URL}
      access: proxy
      jsonData:
        implementation: prometheus
        handleGrafanaManagedAlerts: true
    - name: Loki
      type: loki
      url: ${LOKI_URL}
      access: proxy
      jsonData:
        maxLines: 1000

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
    - name: 'kubernetes'
      orgId: 1
      folder: 'Kubernetes'
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/kubernetes
    - name: 'infrastructure'
      orgId: 1
      folder: 'Infrastructure'
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/infrastructure

# Default dashboards - Curated and organized for optimal Kubernetes monitoring
dashboards:
  # === OVERVIEW DASHBOARDS (Main folder) ===
  default:
    # Main cluster overview - most popular and reliable
    kubernetes-cluster-monitoring:
      gnetId: 7249
      revision: 1
      datasource: Prometheus

    # Cluster resource overview
    k8s-cluster-overview:
      gnetId: 8588
      revision: 1
      datasource: Prometheus

  # === KUBERNETES SPECIFIC DASHBOARDS ===
  kubernetes:
    # Node monitoring - comprehensive and reliable
    node-exporter-full:
      gnetId: 1860
      revision: 37
      datasource: Prometheus

    # Kubernetes API Server
    k8s-api-server:
      gnetId: 12006
      revision: 1
      datasource: Prometheus

    # Kubernetes Pods
    k8s-pods:
      gnetId: 6417
      revision: 1
      datasource: Prometheus

    # Kubernetes Deployments
    k8s-deployments:
      gnetId: 8685
      revision: 1
      datasource: Prometheus

    # Kubernetes StatefulSets
    k8s-statefulsets:
      gnetId: 13473
      revision: 1
      datasource: Prometheus

    # Kubernetes DaemonSets
    k8s-daemonsets:
      gnetId: 12007
      revision: 1
      datasource: Prometheus

    # Kubernetes Services
    k8s-services:
      gnetId: 14623
      revision: 1
      datasource: Prometheus

    # Kubernetes Ingress
    k8s-ingress:
      gnetId: 9614
      revision: 1
      datasource: Prometheus

    # Kubernetes Persistent Volumes
    k8s-persistent-volumes:
      gnetId: 13646
      revision: 2
      datasource: Prometheus

    # Kubernetes Resource Recommendations
    k8s-resource-recommendations:
      gnetId: 13332
      revision: 12
      datasource: Prometheus

    # Kubernetes Capacity Planning
    k8s-capacity-planning:
      gnetId: 5309
      revision: 1
      datasource: Prometheus

    # Kubernetes Networking
    k8s-networking:
      gnetId: 12124
      revision: 1
      datasource: Prometheus

    # ARM64 Node monitoring (replaces problematic raspberry-pi dashboard)
    arm64-node-monitoring:
      gnetId: 11074
      revision: 9
      datasource: Prometheus

  # === INFRASTRUCTURE DASHBOARDS ===
  infrastructure:
    # Prometheus 2.0 Overview
    prometheus-overview:
      gnetId: 3662
      revision: 2
      datasource: Prometheus

    # Prometheus Stats
    prometheus-stats:
      gnetId: 2
      revision: 2
      datasource: Prometheus

    # AlertManager Overview
    alertmanager-overview:
      gnetId: 9578
      revision: 4
      datasource: Prometheus

    # Grafana Overview
    grafana-overview:
      gnetId: 3590
      revision: 3
      datasource: Prometheus

    # Traefik 2.0 Dashboard
    traefik-v2:
      gnetId: 11462
      revision: 1
      datasource: Prometheus

    # Traefik Official Dashboard
    traefik-official:
      gnetId: 4475
      revision: 5
      datasource: Prometheus

    # Node Exporter for Prometheus Dashboard (ARM64 optimized)
    node-exporter-arm64:
      gnetId: 11074
      revision: 9
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
  # Enable feature toggles for better Kubernetes integration
  GF_FEATURE_TOGGLES_ENABLE: "publicDashboards"
  # Improve dashboard loading performance
  GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: "/var/lib/grafana/dashboards/default/kubernetes-cluster-monitoring.json"

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
