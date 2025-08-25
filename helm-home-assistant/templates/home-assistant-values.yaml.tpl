image:
  repository: homeassistant/home-assistant
  tag: "2024.1"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8123
  targetPort: 8123

ingress:
  enabled: ${enable_ingress}
%{ if enable_ingress ~}
  className: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: ${traefik_cert_resolver}
  hosts:
    - host: home-assistant.${domain_name}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: home-assistant-tls
      hosts:
        - home-assistant.${domain_name}
%{ endif ~}

persistence:
  enabled: ${enable_persistence}
%{ if enable_persistence ~}
  existingClaim: ${name}
  mountPath: /config
%{ endif ~}

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

%{ if !disable_arch_scheduling ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

%{ if enable_privileged ~}
securityContext:
  privileged: true
%{ endif ~}

%{ if enable_host_network ~}
hostNetwork: true
dnsPolicy: ClusterFirstWithHostNet
%{ endif ~}

# Home Assistant specific configuration
configuration:
  # Enable the default config
  default_config:
  
  # HTTP configuration
  http:
    use_x_forwarded_for: true
    trusted_proxies:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16

# Probes configuration
probes:
  liveness:
    enabled: true
    path: /
    initialDelaySeconds: 60
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 5
    successThreshold: 1
  readiness:
    enabled: true
    path: /
    initialDelaySeconds: 30
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
    successThreshold: 1
  startup:
    enabled: true
    path: /
    initialDelaySeconds: 0
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 30
    successThreshold: 1

# Additional environment variables
env:
  TZ: "UTC"