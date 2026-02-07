image:
  repository: authelia/authelia
  tag: latest
  pullPolicy: IfNotPresent

nameOverride: ${name}
fullnameOverride: ${name}

# Disable PostgreSQL at Helm chart level - force local storage
storage:
  postgres:
    enabled: false
  local:
    enabled: true
    path: /config/db.sqlite3

replicaCount: ${replica_count}

podAnnotations: {}

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: false

service:
  type: ClusterIP
  port: 9091  # Match application port for consistency

ingress:
  enabled: false

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}

%{if node_selector != "" && length(keys(node_selector)) > 0}
nodeSelector:
%{for k, v in node_selector}
  ${k}: ${v}
%{endfor}
%{endif}

tolerations: []

affinity: {}

# Persistence configuration - uses Terraform-managed PVC
persistence:
  enabled: true
  existingClaim: ${pvc_name}

# Use configMap to configure Authelia
configMap:

  server:
    address: tcp://:9091
    disable_healthcheck: false
    tls:
      certificate: /etc/authelia/certificates/public.crt
      key: /etc/authelia/certificates/private.key
      minimum_version: TLS1.2

  log:
    level: info
    format: text
    file_path: ""
    keep_stdout: true

  telemetry:
    metrics:
      enabled: false
      address: tcp://:9959

  theme: dark

  authentication_backend:
    password_reset:
      disable: true
      custom_url: ""
%{if ldap_enabled && ldap_url != "" && ldap_base_dn != ""}
    ldap:
      enabled: true
      url: ${ldap_url}
      implementation: custom
      start_tls: false
      disable_reset_password: true
      disable_startup_check: true
      tls:
        server_name: ''
        skip_verify: false
        minimum_version: TLS1.2
      base_dn: ${ldap_base_dn}
      additional_users_dn: ""
      users_filter: "(&({username_attribute}={input})(objectClass=person))"
      groups_filter: ${ldap_groups_filter}
      group_search_mode: 'ldapfilter'
%{if ldap_bind_dn != "" && ldap_bind_password != ""}
      user: ${ldap_bind_dn}
      password: ${ldap_bind_password}
%{endif}
      attributes:
        distinguished_name: dn
        username: ${ldap_username_attribute}
        display_name: displayName
        mail: mail
        member_of: memberOf
        group_name: cn
%{else}
    ldap:
      enabled: false
    file:
      enabled: true
      path: /config/users_database.yml
%{endif}

  session:
    name: authelia_session
    secret: ${session_secret}
    expiration: 1h
    inactivity: 5m
    same_site: lax
    remember_me: 1M
    redis:
      enabled: false
    cookies:
      - authelia_url: https://authelia.${domain_name}
        default_redirection_url: https://authelia.${domain_name}

  regulation:
    max_retries: 5
    find_time: 2m
    ban_time: 5m

  storage:
    encryption_key: ${encryption_key}
    postgres:
      enabled: false
    local:
      enabled: true
      path: /config/db.sqlite3

  notifier:
    disable_startup_check: true
    filesystem:
      filename: /config/notification.txt

  # TOTP configuration
  totp:
    enabled: ${totp_enabled}
    issuer: authelia.com
    algorithm: sha1
    digits: 6
    period: 30
    skew: 1

  %{if duo_enabled}
  # Duo Security configuration
  duo_api:
    hostname: ${duo_api_hostname}
    integration_key: ${duo_integration_key}
    secret_key: ${duo_secret_key}
    enable: true
  %{else}
  duo_api:
    enable: false
  %{endif}

  # Default policy for access control
  access_control:
    default_policy: ${default_policy}
    networks:
      - name: internal
        networks:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
    rules:
      - domain: "*.${domain_name}"
        policy: ${default_policy}
        subject:
          - ["group:admins"]

  # OIDC provider configuration (always included to satisfy Helm chart requirements)
  identity_providers:
    oidc:
      enabled: ${oidc_enabled}
  %{if oidc_enabled}
      clients:
  %{for client_name, client_config in oidc_clients}
      - id: "${client_config.client_id}"
        description: "${client_name}"
        secret: "${client_config.client_secret}"
        authorization_policy: ${client_config.authorization_policy}
        scopes:
  %{for scope in client_config.scopes}
          - "${scope}"
  %{endfor}
        redirect_uris:
  %{for uri in client_config.redirect_uris}
          - "${uri}"
  %{endfor}
        userinfo_signing_algorithm: ${client_config.userinfo_signing_algorithm}
  %{endfor}
  %{endif}

  # NTP configuration
  ntp:
    enabled: true
    version: 3
    server: time.cloudflare.com
    max_desync: 10s

  password_policy:
    enabled: false
    min_length: 8
    max_length: 64
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: true

# Init containers
initContainers: []

# Sidecar containers
sidecars: []

# ServiceMonitor configuration for Prometheus
serviceMonitor:
  enabled: ${enable_servicemonitor}
  namespace: ${servicemonitor_namespace}
  interval: 30s
  scrapeTimeout: 10s
