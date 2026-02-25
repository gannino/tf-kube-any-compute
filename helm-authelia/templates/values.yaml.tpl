# Authelia Helm Chart 0.10.49+ - Minimal configuration with external ConfigMap
image:
  registry: docker.io
  repository: authelia/authelia
  tag: latest
  pullPolicy: IfNotPresent

# Pod configuration
pod:
  kind: Deployment
  replicas: ${replica_count}
%{if ldap_enabled && ldap_bind_password != "" || oidc_enabled}
  # Build volumes list conditionally
  extraVolumes:
%{if ldap_enabled && ldap_bind_password != ""}
    - name: ldap-password
      secret:
        secretName: "${ldap_secret_name}"
        defaultMode: 0400
%{endif}
%{if oidc_enabled}
    - name: jwt-key
      secret:
        secretName: "${name}-secrets"
        defaultMode: 0400
%{endif}

  # Build volumeMounts list conditionally
  extraVolumeMounts:
%{if ldap_enabled && ldap_bind_password != ""}
    - name: ldap-password
      mountPath: /secrets/authentication.ldap.password.txt
      subPath: password
      readOnly: true
%{endif}
%{if oidc_enabled}
    - name: jwt-key
      mountPath: /config/jwt.pem
      subPath: JWT_PRIVATE_KEY
      readOnly: true
%{endif}
%{endif}

# Service configuration
service:
  type: ClusterIP
  port: 9091

# ConfigMap - Use external ConfigMap for 0.10.49
# All Authelia application configuration is in the external ConfigMap
configMap:
  existingConfigMap: "${name}-config"

# Redis configuration for distributed session storage
# Note: The Authelia Helm chart does NOT include a Redis subchart dependency
# You must deploy Redis separately and provide the address below
%{if redis_enabled}
# Configure Authelia to connect to external Redis instance
# The redis_address variable should point to your Redis service
redis:
  enabled: true
  host: "${name}-redis.${namespace}.svc.cluster.local"
  port: 6379
%{endif}
