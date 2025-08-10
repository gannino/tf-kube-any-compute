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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.vault_scripts](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.vault_unsealer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_job.vault_init](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_manifest.vault_ingress_route](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_role.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [time_sleep.wait_for_crd_registration](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service_account.vault](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"vault"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL. | `string` | `"https://helm.releases.hashicorp.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the Helm chart to deploy. Refer to <https://artifacthub.io/packages/helm/hashicorp/vault> for available versions. | `string` | `"0.28.0"` | no |
| <a name="input_consul_address"></a> [consul\_address](#input\_consul\_address) | Consul service address in hostname:port format (e.g., consul-server.consul.svc.cluster.local:8500). | `string` | `"consul-server.consul.svc.cluster.local:8500"` | no |
| <a name="input_consul_port"></a> [consul\_port](#input\_consul\_port) | Port number for Consul service | `number` | `8500` | no |
| <a name="input_consul_token"></a> [consul\_token](#input\_consul\_token) | Consul ACL token for Vault authentication. | `string` | `""` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"50m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name suffix. | `string` | `".local"` | no |
| <a name="input_enable_ingress"></a> [enable\_ingress](#input\_enable\_ingress) | Enable Ingress for Vault UI. | `bool` | `true` | no |
| <a name="input_enable_traefik_ingress"></a> [enable\_traefik\_ingress](#input\_enable\_traefik\_ingress) | n/a | `bool` | `false` | no |
| <a name="input_healthcheck_interval"></a> [healthcheck\_interval](#input\_healthcheck\_interval) | Interval for health check probes | `string` | `"10s"` | no |
| <a name="input_healthcheck_timeout"></a> [healthcheck\_timeout](#input\_healthcheck\_timeout) | Timeout for health check probes | `string` | `"5s"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `true` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `true` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `true` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_ingress_sleep_duration"></a> [ingress\_sleep\_duration](#input\_ingress\_sleep\_duration) | Duration to wait before creating ingress resources | `string` | `"1s"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"128Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"64Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name. | `string` | `"vault"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"vault-stack"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration | <pre>object({<br/>    helm_config = optional(object({<br/>      chart_name       = optional(string)<br/>      chart_repo       = optional(string)<br/>      chart_version    = optional(string)<br/>      timeout          = optional(number)<br/>      disable_webhooks = optional(bool)<br/>      skip_crds        = optional(bool)<br/>      replace          = optional(bool)<br/>      force_update     = optional(bool)<br/>      cleanup_on_fail  = optional(bool)<br/>      wait             = optional(bool)<br/>      wait_for_jobs    = optional(bool)<br/>    }), {})<br/>    labels          = optional(map(string), {})<br/>    template_values = optional(map(any), {})<br/>  })</pre> | <pre>{<br/>  "helm_config": {},<br/>  "labels": {},<br/>  "template_values": {}<br/>}</pre> | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to use for persistent volumes | `string` | `""` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | Size of the persistent volume | `string` | `"2Gi"` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | n/a | `string` | `"default"` | no |
| <a name="input_vault_init_timeout"></a> [vault\_init\_timeout](#input\_vault\_init\_timeout) | Timeout in seconds for Vault initialization | `number` | `600` | no |
| <a name="input_vault_port"></a> [vault\_port](#input\_vault\_port) | Port number for Vault service | `number` | `8200` | no |
| <a name="input_vault_readiness_timeout"></a> [vault\_readiness\_timeout](#input\_vault\_readiness\_timeout) | Timeout in seconds for Vault container readiness | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_common_labels"></a> [common\_labels](#output\_common\_labels) | Common labels applied to all resources |
| <a name="output_consul_backend_address"></a> [consul\_backend\_address](#output\_consul\_backend\_address) | Consul backend address used by Vault |
| <a name="output_consul_port"></a> [consul\_port](#output\_consul\_port) | Consul port used by Vault backend |
| <a name="output_environment_config"></a> [environment\_config](#output\_environment\_config) | Environment configuration summary |
| <a name="output_health_check_endpoint"></a> [health\_check\_endpoint](#output\_health\_check\_endpoint) | Vault health check endpoint |
| <a name="output_health_check_url"></a> [health\_check\_url](#output\_health\_check\_url) | Full health check URL |
| <a name="output_helm_chart_name"></a> [helm\_chart\_name](#output\_helm\_chart\_name) | Helm chart name |
| <a name="output_helm_chart_version"></a> [helm\_chart\_version](#output\_helm\_chart\_version) | Helm chart version deployed |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name |
| <a name="output_ingress_url"></a> [ingress\_url](#output\_ingress\_url) | External ingress URL for Vault web UI |
| <a name="output_kubectl_commands"></a> [kubectl\_commands](#output\_kubectl\_commands) | Useful kubectl commands for Vault operations |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Vault namespace |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Vault service name |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | Internal service URL for Vault (cluster-local) |
| <a name="output_storage_class"></a> [storage\_class](#output\_storage\_class) | Storage class used for Vault persistence |
| <a name="output_storage_size"></a> [storage\_size](#output\_storage\_size) | Storage size allocated for Vault |
| <a name="output_vault_address"></a> [vault\_address](#output\_vault\_address) | Vault server address (hostname:port format for client configuration) |
| <a name="output_vault_port"></a> [vault\_port](#output\_vault\_port) | Vault server port |
| <a name="output_web_ui_url"></a> [web\_ui\_url](#output\_web\_ui\_url) | Vault web UI URL |
<!-- END_TF_DOCS -->
