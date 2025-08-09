enableCRDs: true
replicaCount: 2
auditInterval: 60s
enableWebhook: true

extraArgs:
  - --operation=audit
  - --operation=status

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
  runAsUser: 1000

nodeSelector:
%{~ if cpu_arch != "" && !disable_arch_scheduling ~}
  kubernetes.io/arch: ${cpu_arch}
%{~ endif ~}