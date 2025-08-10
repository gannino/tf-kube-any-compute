service:
  type: ClusterIP
  name: ${name}-frontend

ingress:
  enabled: false

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

persistence:
  enabled: true
  existingClaim: ${name}

# Set initial admin password via environment variable
env:
  - name: PORTAINER_ADMIN_PASSWORD
    value: "${admin_password}"

%{ if !disable_arch_scheduling ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}
