additionalArguments:
  # Logging and access log settings
  - --log.level=INFO
  - --accesslog=true

  # Health check
  - --ping

  # Forwarded headers configuration for web entrypoint
  - --entrypoints.web.forwardedheaders.insecure=true
  - --entrypoints.websecure.forwardedheaders.insecure=true
#   - --entrypoints.web.proxyprotocol.insecure=true
#   - --entrypoints.websecure.proxyprotocol.insecure=true
  - --api.dashboard=true
  - --entrypoints.websecure.http.tls.certresolver=default
  - --certificatesresolvers.default.acme.email=${le_email}
  - --certificatesresolvers.default.acme.storage=/certs/acme.json
  # - --certificatesresolvers.default.acme.tlschallenge
  # - --certificatesresolvers.default.acme.tlschallenge.entrypoint=websecure
  - --certificatesresolvers.default.acme.httpchallenge=true
  - --certificatesresolvers.default.acme.httpchallenge.entrypoint=web
  - --certificatesresolvers.wildcard.acme.email=${le_email}
  - --certificatesresolvers.wildcard.acme.storage=/certs/acme-wildcard.json
  - --certificatesresolvers.wildcard.acme.dnschallenge=true
  - --certificatesresolvers.wildcard.acme.dnschallenge.provider=hurricane
  - --certificatesresolvers.wildcard.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53
  - --certificatesresolvers.wildcard.acme.dnschallenge.delayBeforeCheck=150s
  - --certificatesresolvers.wildcard.acme.dnschallenge.disablepropagationcheck=false

entryPoints:
  web:
    address: ":${http_port}"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
  websecure:
    address: ":${https_port}"
    forwardedHeaders:
      insecure: true
  traefik:
    address: ":${dashboard_port}"
    forwardedHeaders:
      insecure: true
  metrics:
    address: ":${metrics_port}"

ports:
  web:
    expose:
      enabled: true
    exposedPort: 80
    protocol: TCP
  websecure:
    expose:
      enabled: true
    exposedPort: 443
    protocol: TCP
  metrics:
    expose:
      enabled: false
    port: 9100
    protocol: TCP
  traefik:
    expose:
      enabled: true
    exposedPort: 8080
    protocol: TCP

ingressRoute:
  dashboard:
    enabled: false

metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addServicesLabels: true

api:
  dashboard: true
  insecure: true

providers:
  kubernetesCRD:
    enabled: true
    allowCrossNamespace: true
    allowExternalNameServices: true
    namespaces: []
    ingressClass: traefik

fullnameOverride: ${ingress_gateway_name}

%{ if !disable_arch_scheduling ~}
nodeSelector:
  kubernetes.io/arch: ${cpu_arch}
%{ endif ~}

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

service:
  type: LoadBalancer
  spec:
    externalTrafficPolicy: Local

additionalService:
  enabled: true
  ports:
    - name: traefik
      port: 8080
      targetPort: 8080

persistence:
  enabled: true
  existingClaim: ${ingress_gateway_name}-certs
  path: /certs

rbac:
  enabled: true

env:
  - name: HURRICANE_TOKENS
    valueFrom:
      secretKeyRef:
        name: he-dns-tokens-credentials
        key: tokens
  - name: HURRICANE_POLLING_INTERVAL
    value: "5"
  - name: HURRICANE_PROPAGATION_TIMEOUT
    value: "300"
  - name: HURRICANE_SEQUENCE_INTERVAL
    value: "60"
  - name: HURRICANE_HTTP_TIMEOUT
    value: "30"
