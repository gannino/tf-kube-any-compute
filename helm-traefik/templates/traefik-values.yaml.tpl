additionalArguments:
  # Logging and access log settings
  - --log.level=INFO
  - --accesslog=true

  # Health check
  - --ping

%{ if enable_tracing ~}
  # Tracing configuration
  - --tracing=true
%{ if tracing_backend == "loki" ~}
  - --tracing.loki=true
  - --tracing.loki.endpoint=${loki_endpoint}
%{ endif ~}
%{ if tracing_backend == "jaeger" ~}
  - --tracing.jaeger=true
  - --tracing.jaeger.collector.endpoint=${jaeger_endpoint}
%{ endif ~}
%{ endif ~}

  # Forwarded headers configuration for web entrypoint
  - --entrypoints.web.forwardedheaders.insecure=true
  - --entrypoints.websecure.forwardedheaders.insecure=true
  - --api.dashboard=true

  # Certificate resolvers configuration
%{ if try(cert_resolvers.default, null) != null ~}
  - --entrypoints.websecure.http.tls.certresolver=default
  - --certificatesresolvers.default.acme.email=${le_email}
  - --certificatesresolvers.default.acme.storage=/certs/acme.json
%{ if try(cert_resolvers.default.challenge_type, "http") == "http" ~}
  - --certificatesresolvers.default.acme.httpchallenge=true
  - --certificatesresolvers.default.acme.httpchallenge.entrypoint=web
%{ else ~}
  - --certificatesresolvers.default.acme.dnschallenge=true
  - --certificatesresolvers.default.acme.dnschallenge.provider=${try(cert_resolvers.default.dns_provider, dns_config.primary_provider)}
  - --certificatesresolvers.default.acme.dnschallenge.resolvers=${join(",", try(dns_config.challenge_config.resolvers, ["1.1.1.1:53", "8.8.8.8:53"]))}
  - --certificatesresolvers.default.acme.dnschallenge.propagation.delayBeforeChecks=${try(dns_config.challenge_config.delay_before_check, "150s")}
  - --certificatesresolvers.default.acme.dnschallenge.disablepropagationcheck=${try(dns_config.challenge_config.disable_propagation_check, false)}
%{ endif ~}
%{ endif ~}
  # DNS provider-named certificate resolver with main domain
  - --certificatesresolvers.${dns_config.primary_provider}.acme.email=${le_email}
  - --certificatesresolvers.${dns_config.primary_provider}.acme.storage=/certs/acme-${dns_config.primary_provider}.json
  - --certificatesresolvers.${dns_config.primary_provider}.acme.dnschallenge=true
  - --certificatesresolvers.${dns_config.primary_provider}.acme.dnschallenge.provider=${dns_config.primary_provider}
  - --certificatesresolvers.${dns_config.primary_provider}.acme.dnschallenge.resolvers=${join(",", try(dns_config.challenge_config.resolvers, ["1.1.1.1:53", "8.8.8.8:53"]))}
  - --certificatesresolvers.${dns_config.primary_provider}.acme.dnschallenge.propagation.delayBeforeChecks=${try(dns_config.challenge_config.delay_before_check, "150s")}
  - --certificatesresolvers.${dns_config.primary_provider}.acme.dnschallenge.disablepropagationcheck=${try(dns_config.challenge_config.disable_propagation_check, false)}

%{ for resolver_name, resolver in try(cert_resolvers.custom, {}) ~}
  - --certificatesresolvers.${resolver_name}.acme.email=${le_email}
  - --certificatesresolvers.${resolver_name}.acme.storage=/certs/acme-${resolver_name}.json
%{ if try(resolver.challenge_type, "dns") == "http" ~}
  - --certificatesresolvers.${resolver_name}.acme.httpchallenge=true
  - --certificatesresolvers.${resolver_name}.acme.httpchallenge.entrypoint=web
%{ else ~}
  - --certificatesresolvers.${resolver_name}.acme.dnschallenge=true
  - --certificatesresolvers.${resolver_name}.acme.dnschallenge.provider=${try(resolver.dns_provider, dns_config.primary_provider)}
  - --certificatesresolvers.${resolver_name}.acme.dnschallenge.resolvers=${join(",", try(dns_config.challenge_config.resolvers, ["1.1.1.1:53", "8.8.8.8:53"]))}
  - --certificatesresolvers.${resolver_name}.acme.dnschallenge.propagation.delayBeforeChecks=${try(dns_config.challenge_config.delay_before_check, "150s")}
  - --certificatesresolvers.${resolver_name}.acme.dnschallenge.disablepropagationcheck=${try(dns_config.challenge_config.disable_propagation_check, false)}
%{ endif ~}
%{ endfor ~}

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

# Plugin storage volume
additionalVolumes:
  - name: plugins
    persistentVolumeClaim:
      claimName: ${ingress_gateway_name}-plugins-storage

# Plugin storage mount
additionalVolumeMounts:
  - name: plugins
    mountPath: /plugins

# Experimental plugins configuration
experimental:
  plugins:
    ldapAuth:
      moduleName: "github.com/wiltonsr/ldapAuth"
      version: "v0.1.5"

rbac:
  enabled: true

env:
%{ if try(dns_config.primary_provider, "hurricane") == "hurricane" ~}
  # Hurricane Electric DNS provider configuration
  - name: HURRICANE_TOKENS
    valueFrom:
      secretKeyRef:
        name: he-dns-tokens-credentials
        key: tokens
  - name: HURRICANE_POLLING_INTERVAL
    value: "${try(dns_config.challenge_config.polling_interval, "5")}"
  - name: HURRICANE_PROPAGATION_TIMEOUT
    value: "${try(dns_config.challenge_config.propagation_timeout, "300")}"
  - name: HURRICANE_SEQUENCE_INTERVAL
    value: "${try(dns_config.challenge_config.sequence_interval, "60")}"
  - name: HURRICANE_HTTP_TIMEOUT
    value: "${try(dns_config.challenge_config.http_timeout, "30")}"
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "cloudflare" ~}
  # Cloudflare DNS provider configuration
  - name: CF_API_EMAIL
    valueFrom:
      secretKeyRef:
        name: cloudflare-dns-credentials
        key: email
  - name: CF_API_KEY
    valueFrom:
      secretKeyRef:
        name: cloudflare-dns-credentials
        key: api-key
  - name: CF_DNS_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: cloudflare-dns-credentials
        key: dns-token
        optional: true
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "route53" ~}
  # AWS Route53 DNS provider configuration
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: route53-dns-credentials
        key: access-key-id
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: route53-dns-credentials
        key: secret-access-key
  - name: AWS_REGION
    valueFrom:
      secretKeyRef:
        name: route53-dns-credentials
        key: region
        optional: true
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "digitalocean" ~}
  # DigitalOcean DNS provider configuration
  - name: DO_AUTH_TOKEN
    valueFrom:
      secretKeyRef:
        name: digitalocean-dns-credentials
        key: auth-token
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "gandi" ~}
  # Gandi DNS provider configuration
  - name: GANDI_API_KEY
    valueFrom:
      secretKeyRef:
        name: gandi-dns-credentials
        key: api-key
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "namecheap" ~}
  # Namecheap DNS provider configuration
  - name: NAMECHEAP_API_USER
    valueFrom:
      secretKeyRef:
        name: namecheap-dns-credentials
        key: api-user
  - name: NAMECHEAP_API_KEY
    valueFrom:
      secretKeyRef:
        name: namecheap-dns-credentials
        key: api-key
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "godaddy" ~}
  # GoDaddy DNS provider configuration
  - name: GODADDY_API_KEY
    valueFrom:
      secretKeyRef:
        name: godaddy-dns-credentials
        key: api-key
  - name: GODADDY_API_SECRET
    valueFrom:
      secretKeyRef:
        name: godaddy-dns-credentials
        key: api-secret
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "ovh" ~}
  # OVH DNS provider configuration
  - name: OVH_ENDPOINT
    valueFrom:
      secretKeyRef:
        name: ovh-dns-credentials
        key: endpoint
  - name: OVH_APPLICATION_KEY
    valueFrom:
      secretKeyRef:
        name: ovh-dns-credentials
        key: application-key
  - name: OVH_APPLICATION_SECRET
    valueFrom:
      secretKeyRef:
        name: ovh-dns-credentials
        key: application-secret
  - name: OVH_CONSUMER_KEY
    valueFrom:
      secretKeyRef:
        name: ovh-dns-credentials
        key: consumer-key
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "linode" ~}
  # Linode DNS provider configuration
  - name: LINODE_TOKEN
    valueFrom:
      secretKeyRef:
        name: linode-dns-credentials
        key: token
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "vultr" ~}
  # Vultr DNS provider configuration
  - name: VULTR_API_KEY
    valueFrom:
      secretKeyRef:
        name: vultr-dns-credentials
        key: api-key
%{ endif ~}
%{ if try(dns_config.primary_provider, "hurricane") == "hetzner" ~}
  # Hetzner DNS provider configuration
  - name: HETZNER_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: hetzner-dns-credentials
        key: api-token
%{ endif ~}
%{ for provider in try(dns_config.additional_providers, []) ~}
  # Additional DNS provider: ${provider.name}
%{ for key, value in provider.config ~}
  - name: ${key}
    valueFrom:
      secretKeyRef:
        name: ${provider.name}-dns-credentials
        key: ${replace(lower(key), "_", "-")}
%{ endfor ~}
%{ endfor ~}
