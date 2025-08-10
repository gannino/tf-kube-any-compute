# Loki configuration
deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: 2024-04-01
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: loki_index_
          period: 24h

# Single binary deployment - minimal resources for ARM64
singleBinary:
  replicas: 1
  persistence:
    enabled: true
    storageClass: "${STORAGE_CLASS}"
    size: ${STORAGE_SIZE}
  resources:
    limits:
      cpu: ${CPU_LIMIT}
      memory: ${MEMORY_LIMIT}
    requests:
      cpu: ${CPU_REQUEST}
      memory: ${MEMORY_REQUEST}

# Disable all caching components for minimal deployment
chunksCache:
  enabled: false

resultsCache:
  enabled: false

memcached:
  enabled: false

memcachedChunks:
  enabled: false

memcachedFrontend:
  enabled: false

memcachedIndexQueries:
  enabled: false

memcachedIndexWrites:
  enabled: false

# Node selector for architecture
%{ if CPU_ARCH != "" ~}
nodeSelector:
  kubernetes.io/arch: ${CPU_ARCH}
%{ endif ~}

# Disable other components for single binary mode
backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0

# Gateway - minimal resources
gateway:
  enabled: true
  replicas: 1
  resources:
    limits:
      cpu: 50m
      memory: 64Mi
    requests:
      cpu: 25m
      memory: 32Mi

# Disable canary for minimal deployment
canary:
  enabled: false

# Monitoring
monitoring:
  serviceMonitor:
    enabled: true
  selfMonitoring:
    enabled: false
    grafanaAgent:
      installOperator: false

# Test pod
test:
  enabled: false
