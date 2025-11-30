image:
  repository: openhab/openhab
  tag: "4.1.1"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080
  targetPort: 8080

%{ if enable_karaf_console ~}
# Karaf console service (for debugging)
karafService:
  type: ClusterIP
  port: 8101
  targetPort: 8101
%{ endif ~}

ingress:
  enabled: ${enable_ingress}
%{ if enable_ingress ~}
  className: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: ${traefik_cert_resolver}
  hosts:
    - host: openhab.${domain_name}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: openhab-tls
      hosts:
        - openhab.${domain_name}
%{ endif ~}

persistence:
  enabled: ${enable_persistence}
%{ if enable_persistence ~}
  # Main data volume
  data:
    enabled: true
    existingClaim: ${name}-data
    mountPath: /openhab/userdata
  # Addons volume
  addons:
    enabled: true
    existingClaim: ${name}-addons
    mountPath: /openhab/addons
  # Configuration volume
  conf:
    enabled: true
    existingClaim: ${name}-conf
    mountPath: /openhab/conf
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

# openHAB specific configuration
env:
  # Java memory settings optimized for container
  - name: JAVA_OPTS
    value: "-Xms512m -Xmx1536m -XX:+UseG1GC -XX:+UseStringDeduplication"
  # Timezone
  - name: TZ
    value: "UTC"
  # openHAB specific settings
  - name: OPENHAB_HTTP_PORT
    value: "8080"
  - name: OPENHAB_HTTPS_PORT
    value: "8443"
%{ if enable_karaf_console ~}
  - name: KARAF_CONSOLE_PORT
    value: "8101"
%{ endif ~}

# Probes configuration optimized for Java startup
probes:
  liveness:
    enabled: true
    httpGet:
      path: /rest/
      port: 8080
    initialDelaySeconds: 120
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 5
    successThreshold: 1
  readiness:
    enabled: true
    httpGet:
      path: /rest/
      port: 8080
    initialDelaySeconds: 60
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
    successThreshold: 1
  startup:
    enabled: true
    httpGet:
      path: /rest/
      port: 8080
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 30
    successThreshold: 1

# Additional volumes for device access (if needed)
%{ if enable_privileged ~}
extraVolumes:
  - name: dev-ttyusb
    hostPath:
      path: /dev/ttyUSB0
      type: CharDevice
  - name: dev-ttyacm
    hostPath:
      path: /dev/ttyACM0
      type: CharDevice

extraVolumeMounts:
  - name: dev-ttyusb
    mountPath: /dev/ttyUSB0
  - name: dev-ttyacm
    mountPath: /dev/ttyACM0
%{ endif ~}
