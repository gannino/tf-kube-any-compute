# Vault Helm Module

This Terraform module deploys HashiCorp Vault for secrets management and encryption using the official Helm chart.

## Features

- **🔐 Secrets Management**: Secure storage and access to secrets, tokens, and certificates
- **🔑 Dynamic Secrets**: Generate secrets on-demand for databases, cloud providers, and more
- **🛡️ Encryption as a Service**: Encrypt/decrypt data without storing it
- **🏛️ Policy Management**: Fine-grained access control with policies
- **🔄 Auto-Unseal**: Kubernetes-based auto-unsealing for high availability
- **📋 Audit Logging**: Comprehensive audit trails for compliance
- **🌐 Multi-Platform**: Support for various secret backends and auth methods
- **⚡ High Availability**: Clustering and replication support

## Usage

### Basic Usage

```hcl
module "vault" {
  source = "./helm-vault"
  
  namespace = "vault-system"
  
  domain_name = "example.com"
  storage_class = "fast-ssd"
}
```

### Advanced Configuration

```hcl
module "vault" {
  source = "./helm-vault"
  
  namespace     = "vault-system"
  chart_version = "0.28.1"
  
  # Ingress configuration
  domain_name          = "example.com"
  traefik_cert_resolver = "letsencrypt"
  
  # Storage configuration
  storage_class = "fast-ssd"
  storage_size  = "5Gi"
  
  # HA configuration
  ha_enabled = true
  replicas   = 3
  
  # Resource configuration
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Resources

| Name | Type |
|------|------|
| kubernetes_namespace.this | resource |
| kubernetes_service_account.vault | resource |
| kubernetes_cluster_role_binding.vault | resource |
| kubernetes_config_map.vault_config | resource |
| kubernetes_job.vault_init | resource |
| kubernetes_deployment.vault_unsealer | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for Vault | `string` | `"vault-system"` | no |
| name | Helm release name | `string` | `"vault"` | no |
| chart_name | Helm chart name | `string` | `"vault"` | no |
| chart_repo | Helm repository | `string` | `"https://helm.releases.hashicorp.com"` | no |
| chart_version | Helm chart version | `string` | `"0.28.1"` | no |
| ha_enabled | Enable high availability mode | `bool` | `false` | no |
| replicas | Number of Vault replicas | `number` | `1` | no |
| storage_class | Storage class for Vault | `string` | `"hostpath"` | no |
| storage_size | Storage size for Vault | `string` | `"1Gi"` | no |
| cpu_limit | CPU limit for Vault pods | `string` | `"500m"` | no |
| memory_limit | Memory limit for Vault pods | `string` | `"512Mi"` | no |
| cpu_request | CPU request for Vault pods | `string` | `"250m"` | no |
| memory_request | Memory request for Vault pods | `string` | `"256Mi"` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |
| domain_name | Domain name for ingress | `string` | `".local"` | no |
| traefik_cert_resolver | Traefik certificate resolver | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Vault namespace |
| vault_url | Vault web UI URL |
| root_token | Initial root token (sensitive) |
| unseal_keys | Vault unseal keys (sensitive) |

## Vault Initialization

### Auto-Initialization

The module includes an initialization job that:

1. **Initializes Vault**: Creates master keys and root token
2. **Auto-Unseals**: Unseals Vault using Kubernetes secrets
3. **Stores Keys**: Securely stores unseal keys in Kubernetes secrets
4. **Enables Auth**: Configures Kubernetes authentication method

### Manual Initialization

If auto-initialization is disabled:

```bash
# Initialize Vault manually
kubectl exec -n vault-system vault-0 -- vault operator init

# Unseal Vault (repeat for each key)
kubectl exec -n vault-system vault-0 -- vault operator unseal <unseal-key>

# Authenticate with root token
kubectl exec -n vault-system vault-0 -- vault auth <root-token>
```

## Authentication Methods

### Kubernetes Authentication

Automatically configured for pod-based authentication:

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

### Additional Auth Methods

```bash
# Enable userpass authentication
vault auth enable userpass

# Create user
vault write auth/userpass/users/myuser \
    password=mypassword \
    policies=mypolicy

# Enable LDAP authentication
vault auth enable ldap

# Configure LDAP
vault write auth/ldap/config \
    url="ldap://ldap.example.com" \
    userdn="ou=Users,dc=example,dc=com" \
    userattr="uid" \
    groupdn="ou=Groups,dc=example,dc=com" \
    groupattr="cn"
```

## Policy Management

### Basic Policies

```hcl
# Example policy for application secrets
path "secret/data/myapp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}
```

### Policy Assignment

```bash
# Create policy
vault policy write myapp-policy - <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# Assign policy to Kubernetes service account
vault write auth/kubernetes/role/myapp-role \
    bound_service_account_names=myapp \
    bound_service_account_namespaces=default \
    policies=myapp-policy \
    ttl=24h
```

## Secret Engines

### Key-Value Store v2

```bash
# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Store a secret
vault kv put secret/myapp/database \
    username=dbuser \
    password=supersecret

# Read a secret
vault kv get secret/myapp/database
```

### Dynamic Secrets

```bash
# Enable database secrets engine
vault secrets enable database

# Configure database connection
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mysql.default.svc.cluster.local:3306)/" \
    allowed_roles="my-role" \
    username="vault" \
    password="vaultpassword"

# Create role for dynamic credentials
vault write database/roles/my-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"

# Generate dynamic credentials
vault read database/creds/my-role
```

## High Availability

### Raft Storage Backend

For production deployments with HA:

```yaml
# Vault HA configuration
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        storage "raft" {
          path = "/vault/data"
        }
        service_registration "kubernetes" {}
```

### Clustering

```bash
# Join additional nodes to cluster
vault operator raft join http://vault-0.vault-internal:8200

# Check cluster status
vault operator raft list-peers
```

## Backup & Recovery

### Snapshot Creation

```bash
# Create snapshot
vault operator raft snapshot save backup.snap

# Restore from snapshot
vault operator raft snapshot restore backup.snap
```

### Automated Backups

```yaml
# CronJob for automated backups
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vault-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: vault-backup
            image: vault:latest
            command:
            - /bin/sh
            - -c
            - |
              vault operator raft snapshot save /backup/vault-$(date +%Y%m%d-%H%M%S).snap
```

## Integration Examples

### Application Secret Injection

```yaml
# Pod with Vault Agent sidecar
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "myapp-role"
    vault.hashicorp.com/agent-inject-secret-database: "secret/data/myapp/database"
spec:
  serviceAccountName: myapp
  containers:
  - name: myapp
    image: myapp:latest
```

### Vault CSI Driver

```yaml
# SecretProviderClass for CSI driver
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault-system.svc.cluster.local:8200"
    roleName: "myapp-role"
    objects: |
      - objectName: "database-username"
        secretPath: "secret/data/myapp/database"
        secretKey: "username"
      - objectName: "database-password"
        secretPath: "secret/data/myapp/database"
        secretKey: "password"
```

## Monitoring & Observability

### Vault Metrics

```yaml
# Prometheus configuration for Vault
scrape_configs:
  - job_name: 'vault'
    static_configs:
      - targets: ['vault.vault-system.svc.cluster.local:8200']
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    bearer_token: '<vault-token>'
```

### Audit Logging

```bash
# Enable audit logging
vault audit enable file file_path=/vault/logs/audit.log

# Enable syslog audit
vault audit enable syslog tag="vault" facility="AUTH"
```

## Security Considerations

- **Root Token Rotation**: Regularly rotate the root token
- **Policy Least Privilege**: Grant minimal required permissions
- **Network Segmentation**: Use network policies to restrict access
- **Audit Logs**: Monitor and analyze audit logs regularly
- **Backup Encryption**: Encrypt backup snapshots
- **Key Rotation**: Regularly rotate encryption keys

## Troubleshooting

### Common Issues

1. **Sealed Vault**: Check unsealing process and keys
2. **Authentication Failures**: Verify auth method configuration
3. **Policy Errors**: Check policy syntax and assignments
4. **Storage Issues**: Verify persistent volume access

### Debug Commands

```bash
# Check Vault status
kubectl exec -n vault-system vault-0 -- vault status

# View Vault logs
kubectl logs -n vault-system vault-0

# Check unseal status
kubectl exec -n vault-system vault-0 -- vault operator unseal -status

# Test authentication
kubectl exec -n vault-system vault-0 -- vault auth -method=kubernetes role=myapp-role jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

## Performance Tuning

### Resource Optimization

```hcl
# Production configuration
cpu_limit = "2000m"
memory_limit = "2Gi"
storage_size = "20Gi"

# Development configuration
cpu_limit = "500m"
memory_limit = "512Mi"
storage_size = "5Gi"
```

### Storage Backend Tuning

```yaml
# Raft performance tuning
storage "raft" {
  path = "/vault/data"
  performance_multiplier = 1
  autopilot_reconcile_interval = "10s"
  autopilot_update_interval = "2s"
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT
