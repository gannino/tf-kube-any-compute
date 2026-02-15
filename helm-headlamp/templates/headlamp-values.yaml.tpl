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

# Persistence configuration - Headlamp chart creates and manages its own PVC
# This is for main Headlamp data storage
persistence:
  enabled: ${PERSISTENCE_ENABLED}
%{ if PERSISTENCE_ENABLED ~}
  # Chart will create PVC with these settings
  storageClass: ${STORAGE_CLASS}
  size: ${PERSISTENT_DISK_SIZE}
  accessModes:
    - ReadWriteOnce
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
%{ if PLUGINS_COUNT > 0 ~}
plugins:
  enabled:
%{ for plugin in PLUGINS_ENABLED ~}
    - ${plugin}
%{ endfor ~}
%{ endif ~}

# === CRITICAL: Pod Security Context for writable volumes ===
# fsGroup ensures all volumes are writable by headlamp group (GID 101)
# fsGroupChangePolicy: OnRootMismatch forces permission changes even for pre-existing dirs
podSecurityContext:
  fsGroup: 101
  fsGroupChangePolicy: OnRootMismatch

# Leave container securityContext minimal - let container defaults apply
securityContext:
  runAsNonRoot: true
  # DO NOT set runAsUser or runAsGroup - container defaults (100:101) work correctly

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

# === CRITICAL: Volume Configuration ===
# Headlamp needs writable /home/headlamp/.config for:
# - Session storage (OIDC sessions)
# - Plugin manager
# - User plugins
# - Configuration files

volumes:
  # Writable config directory for sessions and plugins
  # Using emptyDir for ephemeral session storage (survives restarts, not pod deletion)
  # For persistent storage across pod deletions, use persistence.enabled=true above
  - name: headlamp-config
    emptyDir:
      sizeLimit: "100Mi"
%{ if PLUGINS_VOLUME_ENABLED ~}
  # Plugins PVC for persistent plugin storage
  - name: plugins
    persistentVolumeClaim:
      claimName: ${NAME}-plugins
%{ endif ~}

volumeMounts:
  # Mount writable config directory
  # This makes /home/headlamp/.config writable for sessions
  - name: headlamp-config
    mountPath: /home/headlamp/.config
%{ if PLUGINS_VOLUME_ENABLED ~}
  # Mount plugins directory
  - name: plugins
    mountPath: /headlamp/plugins
%{ endif ~}

# Extra environment variables for debugging
env:
  - name: LOG_LEVEL
    value: "debug"

# Service account - managed by Terraform
serviceAccount:
  create: false  # Terraform creates kubernetes_service_account.headlamp_admin
  name: headlamp-admin

# RBAC configuration - managed by Terraform
rbac:
  create: false  # Terraform creates kubernetes_cluster_role.headlamp and kubernetes_cluster_role_binding.headlamp_admin

# Additional configuration for better performance
config:
  # Use inCluster mode - OIDC only works with inCluster=true currently
  # See: https://github.com/kubernetes-sigs/headlamp/issues/4481
  inCluster: true
  inClusterSkipTLSVerify: ${CLUSTER_SKIP_TLS_VERIFY}
  pluginsDir: "/headlamp/plugins"
  enableHelm: true
  baseURL: ""

  # Enable/disable features

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
    clientID: "${OIDC_CLIENT_ID}"
    clientSecret: "${OIDC_CLIENT_SECRET}"
    issuerURL: "${OIDC_ISSUER_URL}"
    scopes: "${OIDC_SCOPES}"
    useAccessToken: ${OIDC_USE_ACCESS_TOKEN}
    usePKCE: true
    skipTLSVerify: ${OIDC_SKIP_TLS_VERIFY}
    callbackURL: "${OIDC_CALLBACK_URL}"
%{ if OIDC_VALIDATOR_CLIENT_ID != "" ~}
    validatorClientID: "${OIDC_VALIDATOR_CLIENT_ID}"
%{ endif ~}
%{ if OIDC_VALIDATOR_ISSUER_URL != "" ~}
    validatorIssuerURL: "${OIDC_VALIDATOR_ISSUER_URL}"
%{ endif ~}
%{ endif ~}
