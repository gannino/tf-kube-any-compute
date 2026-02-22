# Simple Redis Configuration for Alpine Image
# Using official Redis Alpine image with minimal Bitnami chart overrides

# Architecture configuration
%{if NODE_SELECTOR != ""}
nodeSelector:
  kubernetes.io/arch: ${NODE_SELECTOR}
%{ endif }

# Use official Redis Alpine image
image:
  registry: docker.io
  repository: redis
  tag: 7.2-alpine
  pullPolicy: IfNotPresent

# Standalone architecture
architecture: standalone

# Disable authentication for simplicity
auth:
  enabled: false

# Disable replica
replica:
  replicaCount: 0

# Resource configuration
resources:
  limits:
    cpu: ${CPU_LIMIT}
    memory: ${MEMORY_LIMIT}
  requests:
    cpu: ${CPU_REQUEST}
    memory: ${MEMORY_REQUEST}

# Persistence
persistence:
  enabled: ${ENABLE_PERSISTENCE}
%{if ENABLE_PERSISTENCE}
  storageClass: ${STORAGE_CLASS}
  size: ${STORAGE_SIZE}
%{ endif }

# Disable problematic features
sysctlImage:
  enabled: false

networkPolicy:
  enabled: false

metrics:
  enabled: false

# Simple Redis configuration
master:
  configuration: |-
    maxmemory-policy allkeys-lru
    save 900 1
    save 300 10
    save 60 10000

# Security contexts
podSecurityContext:
  enabled: true
  fsGroup: 1001

containerSecurityContext:
  enabled: true
  runAsUser: 1001
  runAsNonRoot: true
