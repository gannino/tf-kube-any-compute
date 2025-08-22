# ============================================================================
# NODE-RED HELM VALUES TEMPLATE
# ============================================================================

# Image configuration
image:
  repository: nodered/node-red
  tag: "latest"
  pullPolicy: IfNotPresent

# Deployment configuration
replicaCount: 1

# Service configuration
service:
  type: ${service_type}
  port: ${service_port}
  targetPort: 1880

# Resource limits
resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

# Node selector for architecture
%{ if length(node_selector) > 0 ~}
nodeSelector:
%{ for key, value in node_selector ~}
  ${key}: ${value}
%{ endfor ~}
%{ endif ~}

# Security context
securityContext:
  runAsUser: ${security_context.runAsUser}
  runAsGroup: ${security_context.runAsGroup}
  fsGroup: ${security_context.fsGroup}

# Persistence configuration
%{ if enable_persistence ~}
persistence:
  enabled: true
  existingClaim: "${name}-data"
  mountPath: /data
%{ else ~}
persistence:
  enabled: false
%{ endif ~}

# Environment variables
env:
%{ for key, value in environment_variables ~}
  - name: ${key}
    value: "${value}"
%{ endfor ~}

# Ingress configuration (handled by Traefik IngressRoute)
ingress:
  enabled: false

# Pod annotations
podAnnotations:
  prometheus.io/scrape: "false"

# Liveness and readiness probes
livenessProbe:
  httpGet:
    path: /
    port: 1880
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 1880
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

# Additional configuration for Node-RED
nodeRed:
  # Enable projects feature
  projects:
    enabled: true

  # Flow file configuration
  flowFile: flows.json

  # Credential secret
  credentialSecret: ""

  # Admin auth (disabled by default for homelab use)
  adminAuth:
    enabled: false

  # HTTP node auth (disabled by default)
  httpNodeAuth:
    enabled: false

# Palette packages installed via separate Kubernetes Job
