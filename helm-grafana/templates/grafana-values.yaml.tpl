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
    default_home_dashboard_path: /var/lib/grafana/dashboards/kubernetes/node-exporter-full.json
    versions_to_keep: 20
    min_refresh_interval: 5s

  # Dashboard state - auto-provision on startup
  provisioning:
    dashboards:
      # Re-sync dashboards from files on startup
      update_interval: 30s

  # UI configuration for better aesthetics
  users:
    default_theme: dark
    home_page: ""

  # Feature toggles
  feature_toggles:
    enable: publicDashboards,tempoSearch,tempoBackendSearch

  # Logging configuration
  log:
    mode: console
    level: info

  # Analytics
  analytics:
    reporting_enabled: false
    check_for_updates: false
    check_for_plugin_updates: false

# Persistence
persistence:
  enabled: ${ENABLE_PERSISTENCE}
  size: ${STORAGE_SIZE}
  storageClassName: "${STORAGE_CLASS}"
initChownData:
  enabled: true
  securityContext:
    runAsUser: 0
    runAsNonRoot: false

# Init container to create all dashboard directories before download
# Note: Runs as Grafana user (472) to comply with non-root pod security policy
extraInitContainers:
  - name: create-dashboard-dirs
    image: busybox:1.36
    securityContext:
      runAsUser: 472
      runAsGroup: 1002
    command: ['sh', '-c', 'mkdir -p /var/lib/grafana/dashboards/overview /var/lib/grafana/dashboards/kubernetes /var/lib/grafana/dashboards/infrastructure /var/lib/grafana/dashboards/application /var/lib/grafana/dashboards/logs /var/lib/grafana/dashboards/virtualization /var/lib/grafana/dashboards/automation && chmod -R 755 /var/lib/grafana/dashboards']
    volumeMounts:
      - name: storage
        mountPath: /var/lib/grafana

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

# Dashboard providers - Organized folder structure for better navigation
# NOTE: disableDeletion=true prevents Grafana from removing manually created dashboards
# Set to false to allow Helm to manage all dashboards in these folders
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'overview'
      orgId: 1
      folder: 'Overview'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/overview
    - name: 'kubernetes'
      orgId: 1
      folder: 'Kubernetes'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/kubernetes
    - name: 'infrastructure'
      orgId: 1
      folder: 'Infrastructure'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/infrastructure
    - name: 'application'
      orgId: 1
      folder: 'Application'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/application
    - name: 'logs'
      orgId: 1
      folder: 'Logs'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/logs
    - name: 'virtualization'
      orgId: 1
      folder: 'Virtualization'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/virtualization
    - name: 'automation'
      orgId: 1
      folder: 'Automation'
      type: file
      disableDeletion: false
      updateIntervalSeconds: 30
      editable: true
      options:
        path: /var/lib/grafana/dashboards/automation

# Dashboards - Curated and organized for optimal monitoring coverage
dashboards:
  # === OVERVIEW DASHBOARDS ===
  overview:
    # Kubernetes Cluster Monitoring - comprehensive cluster view (updated to working dashboard)
    kubernetes-cluster-monitoring:
      gnetId: 31556
      revision: 1
      datasource: Prometheus

  # === KUBERNETES SPECIFIC DASHBOARDS ===
  kubernetes:
    # Node Exporter Full - detailed system metrics (UPDATED to rev 39)
    node-exporter-full:
      gnetId: 1860
      revision: 39
      datasource: Prometheus

    # Kubernetes Cluster (Prometheus) - namespace and pod view
    k8s-cluster-prometheus:
      gnetId: 6417
      revision: 1
      datasource: Prometheus

    # Kubernetes Persistent Volumes - storage monitoring
    k8s-persistent-volumes:
      gnetId: 13646
      revision: 2
      datasource: Prometheus

    # Kubernetes Deployments - workload monitoring
    k8s-deployments:
      gnetId: 8588
      revision: 1
      datasource: Prometheus

  # === INFRASTRUCTURE DASHBOARDS ===
  infrastructure:
    # Prometheus 2.0 Stats - self-monitoring
    prometheus-stats:
      gnetId: 2
      revision: 2
      datasource: Prometheus

    # Alertmanager Overview - alert management (FIXED: was OCR Telemetry)
    alertmanager:
      gnetId: 15157
      revision: 1
      datasource: Prometheus

    # Traefik Dashboard - ingress traffic
    traefik-dashboard:
      gnetId: 4475
      revision: 5
      datasource: Prometheus

    # CoreDNS Monitoring - DNS metrics (FIXED: was KUSAMA validators)
    coredns:
      gnetId: 15762
      revision: 1
      datasource: Prometheus

    # MetalLB Load Balancer - IP allocation (FIXED: was Discourse)
    metallb:
      gnetId: 13332
      revision: 1
      datasource: Prometheus

    # Consul Cluster Monitoring - service mesh
    consul-cluster:
      gnetId: 10642
      revision: 1
      datasource: Prometheus

    # HashiCorp Vault Monitoring - secrets management
    vault-monitoring:
      gnetId: 12904
      revision: 2
      datasource: Prometheus

  # === APPLICATION DASHBOARDS ===
  application:
    # Redis Monitoring - caching layer
    redis:
      gnetId: 763
      revision: 4
      datasource: Prometheus

    # Node.js / N8N Workflow Automation monitoring
    # Community dashboard for Node.js applications (works for n8n)
    # TODO: Search Grafana.com for "n8n" specific dashboard
    nodejs-applications:
      gnetId: 11168
      revision: 2
      datasource: Prometheus

  # === VIRTUALIZATION DASHBOARDS ===
  virtualization:
    # KubeVirt Virtual Machines Monitoring
    # Dashboard ID verified: https://grafana.com/grafana/dashboards/11748-kubevirt/
    # Last updated: 2020-02-19 (Older dashboard, consider alternatives)
    kubevirt:
      gnetId: 11748
      revision: 1
      datasource: Prometheus

  # === AUTOMATION DASHBOARDS ===
  automation:
    # Home Assistant IoT Monitoring
    # Requires Home Assistant Prometheus integration
    # TODO: Search for "home assistant" or "home-assistant" dashboards
    home-assistant:
      gnetId: 11257
      revision: 1
      datasource: Prometheus

    # Node-RED Workflow Automation
    # TODO: Verify latest revision on Grafana.com
    # Search for "node-red" or "nodered" dashboards
    node-red:
      gnetId: 15361
      revision: 1
      datasource: Prometheus

    # MQTT Monitoring (for IoT/automation messaging)
    # Useful for Home Assistant, Node-RED, openHAB
    mqtt:
      gnetId: 10981
      revision: 3
      datasource: Prometheus

  # === LOGS DASHBOARDS ===
  logs:
    # Loki Kubernetes Logs - log exploration
    loki-kubernetes:
      gnetId: 13639
      revision: 2
      datasource: Loki

    # Loki Operational Metrics
    loki-operational:
      gnetId: 14055
      revision: 1
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
  GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: "/var/lib/grafana/dashboards/kubernetes/node-exporter-full.json"

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
