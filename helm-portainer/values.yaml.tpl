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

# Since the chart doesn't support command override, we'll use the web UI approach
# The admin password will be available in the secret for manual setup
# Or we can use the Portainer API to set it programmatically

%{ if !disable_arch_scheduling ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}
