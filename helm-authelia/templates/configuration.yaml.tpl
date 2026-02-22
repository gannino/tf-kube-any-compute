# Authelia Configuration
server:
  address: 'tcp://0.0.0.0:9091/'

log:
  level: ${log_level}
  format: text

%{if ldap_enabled && ldap_url != "" && ldap_base_dn != ""}
authentication_backend:
  ldap:
    implementation: custom
    address: ${ldap_url}
    timeout: 5 seconds
    start_tls: false
    tls:
      server_name: ${ldap_servername}
      skip_verify: ${ldap_tls_skip_verify}
      minimum_version: TLS1.2
    base_dn: ${ldap_base_dn}
    users_filter: "(&({username_attribute}={input})(objectClass=person))"
    groups_filter: ${ldap_groups_filter}
    group_search_mode: filter
    user: ${ldap_bind_dn}
    password: ${ldap_bind_password}
    attributes:
      distinguished_name: dn
      username: ${ldap_username_attribute}
      display_name: displayName
      mail: mail
      member_of: memberOf
      group_name: cn
%{else}
authentication_backend:
  file:
    path: /config/users_database.yml
%{endif}

session:
  name: authelia_session
  same_site: lax
  inactivity: 1h
  expiration: 2h
  remember_me: 1 month
  cookies:
    - name: authelia_session
      domain: ${domain_name}
      authelia_url: https://authelia.${domain_name}
%{if redis_enabled}
  redis:
    host: ${redis_address}
    port: 6379
%{endif}

%{if totp_enabled}
totp:
  issuer: authelia.com
%{endif}

%{if duo_enabled}
duo_api:
  hostname: ${duo_api_hostname}
  integration_key: ${duo_integration_key}
  secret_key: ${duo_secret_key}
%{endif}

access_control:
  default_policy: ${default_policy}
  rules:
    - domain: "*.${domain_name}"
      policy: ${default_policy}
      subject:
      - ["group:admins"]

# Storage configuration - Redis is NOT supported for storage backend
# Only local (SQLite), MySQL, and PostgreSQL are supported
# We use local SQLite with Redis for session storage
storage:
  local:
    path: /config/db.sqlite3

notifier:
  disable_startup_check: true
  filesystem:
    filename: /config/notification.txt

theme: dark

regulation:
  max_retries: 5
  find_time: 2m
  ban_time: 5m

%{if oidc_enabled}
identity_providers:
  oidc:
    # JWKS - use template variable with proper formatting
    jwks:
      - key_id: "authelia-rs256"
        use: "sig"
        algorithm: "RS256"
        key: |
          ${indent(10, chomp(oidc_jwt_private_key))}
    clients:
%{for client_name, client_config in oidc_clients}
    - client_id: "${client_config.client_id}"
      client_name: "${client_name}"
      client_secret: "${client_config.client_secret}"
      public: false
      token_endpoint_auth_method: client_secret_basic
      redirect_uris:
%{for uri in client_config.redirect_uris}
        - "${uri}"
%{endfor}
      scopes:
%{for scope in client_config.scopes}
        - "${scope}"
%{endfor}
      authorization_policy: ${client_config.authorization_policy}
      consent_mode: pre-configured
      id_token_signed_response_key_id: "authelia-rs256"
      authorization_signed_response_key_id: "authelia-rs256"
%{endfor}
%{endif}
