# Headlamp Configuration
# Basic configuration
fullnameOverride: ${NAME}
namespace: ${NAMESPACE}

# Common labels for all resources
commonLabels:
  app.kubernetes.io/managed-by: helm
  app.kubernetes.io/part-of: k8s-infrastructure
  app.kubernetes.io/name: headlamp

# Node selector for architecture-based scheduling
%{ if NODE_SELECTOR != "" ~}
nodeSelector:
  kubernetes.io/arch: ${NODE_SELECTOR}
%{ endif ~}

# Service configuration
service:
  type: ClusterIP
  port: 80
  annotations: {}

# Ingress configuration - disabled (using custom Traefik ingress via terraform)
ingress:
  enabled: false

# Persistence configuration
%{ if PERSISTENCE_ENABLED ~}
persistence:
  enabled: true
  storageClass: ${PERSISTENCE_STORAGE_CLASS}
  size: ${PERSISTENCE_SIZE}
%{ else ~}
persistence:
  enabled: false
%{ endif ~}

# Resource configuration
resources:
  limits:
    cpu: ${CPU_LIMIT}
    memory: ${MEMORY_LIMIT}
  requests:
    cpu: ${CPU_REQUEST}
    memory: ${MEMORY_REQUEST}

# Plugin configuration
%{ if PLUGINS_ENABLED != "" ~}
plugins:
  enabled:
%{ for plugin in PLUGINS_ENABLED ~}
    - ${plugin}
%{ endfor ~}
%{ endif ~}

# Security context
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

# Probes for health checks
livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 30
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

# Replica count
replicaCount: 1

# Update strategy
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 0

# Pod annotations
podAnnotations: {}

# Service account
serviceAccount:
  create: true
  name: headlamp-admin
  automountServiceAccountToken: true

# RBAC configuration
rbac:
  create: true
  rules:
    # Headlamp needs comprehensive permissions for cluster management
    - apiGroups: ["*"]
      resources: ["*"]
      verbs: ["*"]

# Additional configuration for better performance
config:
  # Enable/disable features
  features:
    plugins: true
    mapView: true

  # Timeout settings
  timeouts:
    default: 30000
    resources: 60000

# OIDC Authentication Configuration
%{ if OIDC_ENABLED ~}
oidc:
  clientId: "${OIDC_CLIENT_ID}"
  clientSecret: "${OIDC_CLIENT_SECRET}"
  issuerUrl: "${OIDC_ISSUER_URL}"
  scopes: "${OIDC_SCOPES}"
  useAccessToken: ${OIDC_USE_ACCESS_TOKEN}
%{ if OIDC_VALIDATOR_CLIENT_ID != "" ~}
  validatorClientId: "${OIDC_VALIDATOR_CLIENT_ID}"
%{ endif ~}
%{ if OIDC_VALIDATOR_ISSUER_URL != "" ~}
  validatorIssuerUrl: "${OIDC_VALIDATOR_ISSUER_URL}"
%{ endif ~}
%{ endif ~}
