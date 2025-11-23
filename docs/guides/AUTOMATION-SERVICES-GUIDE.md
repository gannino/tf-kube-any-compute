# Automation Services Guide

## Node-RED and n8n Integration for Homelab Automation

This guide covers the deployment and configuration of Node-RED and n8n automation services in your Kubernetes homelab.

## Quick Start

### Enable Automation Services

```hcl
# terraform.tfvars
services = {
  node_red = true   # Visual programming for IoT
  n8n      = false  # Workflow automation (enable as needed)
}
```

### Deploy with Custom Configuration

```hcl
service_overrides = {
  node_red = {
    cpu_arch           = "arm64"              # For Raspberry Pi
    storage_class      = "nfs-csi"            # Shared storage
    persistent_disk_size = "2Gi"             # Flow storage
    enable_persistence = true                 # Persistent flows

    # Custom palette packages
    palette_packages = [
      "node-red-contrib-home-assistant-websocket",
      "node-red-dashboard",
      "node-red-contrib-influxdb",
      "node-red-contrib-mqtt-broker",
      "node-red-node-pi-gpio",
      "https://github.com/user/custom-nodes.git"
    ]
  }

  n8n = {
    cpu_arch           = "arm64"              # For Raspberry Pi
    storage_class      = "nfs-csi"            # Shared storage
    persistent_disk_size = "5Gi"             # Workflow storage
    enable_persistence = true                 # Persistent workflows
    enable_database    = false                # SQLite for simplicity
  }
}
```

## Node-RED Configuration

### Palette Package Management

Node-RED automatically installs palette packages during deployment:

```hcl
palette_packages = [
  # NPM packages
  "node-red-contrib-home-assistant-websocket",
  "node-red-dashboard",
  "node-red-contrib-influxdb",

  # Git repositories
  "https://github.com/user/custom-nodes.git",
  "git+https://github.com/user/private-nodes.git",
  "git+ssh://git@github.com/user/ssh-nodes.git"
]
```

### Installation Process

1. **Node-RED deploys immediately** (no waiting for packages)
2. **Separate Kubernetes Job** installs packages in background
3. **Restart Node-RED** to load new packages:
   ```bash
   kubectl rollout restart deployment/prod-node-red -n prod-node-red-system
   ```

### Access Node-RED

- **External**: `https://node-red.{domain}`
- **Internal**: `http://node-red.node-red-system.svc.cluster.local:1880`

## n8n Configuration

### Database Options

#### SQLite (Default - Recommended for Homelab)
```hcl
n8n = {
  enable_database = false  # Uses SQLite
}
```

#### PostgreSQL (Advanced)
```hcl
n8n = {
  enable_database = true   # Requires separate PostgreSQL deployment
}
```

### Access n8n

- **External**: `https://n8n.{domain}`
- **Webhooks**: `https://n8n.{domain}/webhook`
- **Internal**: `http://n8n.n8n-system.svc.cluster.local:5678`

## Architecture Support

### ARM64 (Raspberry Pi)
```hcl
service_overrides = {
  node_red = { cpu_arch = "arm64" }
  n8n      = { cpu_arch = "arm64" }
}
```

### Mixed Clusters
```hcl
# Automatic detection and placement
auto_mixed_cluster_mode = true

# Manual overrides
cpu_arch_override = {
  node_red = "arm64"  # IoT services on ARM64
  n8n      = "amd64"  # Workflow processing on AMD64
}
```

## Storage Configuration

### NFS Storage (Recommended)
```hcl
use_nfs_storage = true
nfs_server_address = "192.168.1.100"
nfs_server_path = "/mnt/k8s-storage"

service_overrides = {
  node_red = { storage_class = "nfs-csi" }
  n8n      = { storage_class = "nfs-csi" }
}
```

### HostPath Storage (Single Node)
```hcl
use_hostpath_storage = true

service_overrides = {
  node_red = { storage_class = "hostpath" }
  n8n      = { storage_class = "hostpath" }
}
```

## Resource Management

### Raspberry Pi Optimization
```hcl
service_overrides = {
  node_red = {
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
    cpu_request    = "250m"
    memory_request = "256Mi"
  }

  n8n = {
    cpu_limit      = "1000m"   # Higher for workflow processing
    memory_limit   = "1Gi"
    cpu_request    = "500m"
    memory_request = "512Mi"
  }
}
```

### Production Scaling
```hcl
service_overrides = {
  node_red = {
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
    cpu_request    = "500m"
    memory_request = "512Mi"
  }

  n8n = {
    cpu_limit      = "2000m"
    memory_limit   = "2Gi"
    cpu_request    = "1000m"
    memory_request = "1Gi"
  }
}
```

## SSL Certificates

Both services automatically get SSL certificates via Traefik:

```hcl
service_overrides = {
  node_red = { cert_resolver = "hurricane" }  # DNS provider
  n8n      = { cert_resolver = "hurricane" }  # DNS provider
}
```

## Testing and Validation

### Run Tests
```bash
# Test automation services
terraform test -filter="automation"

# Integration tests
./scripts/test-automation-services.sh

# Specific service tests
./scripts/test-automation-services.sh --domain homelab.local
```

### Health Checks
```bash
# Check Node-RED deployment
kubectl get deployment prod-node-red -n prod-node-red-system

# Check n8n deployment
kubectl get deployment prod-n8n -n prod-n8n-system

# Check persistent storage
kubectl get pvc -n prod-node-red-system
kubectl get pvc -n prod-n8n-system
```

## Troubleshooting

### Node-RED Issues

#### Palette Installation Failed
```bash
# Check palette installer job
kubectl get job prod-node-red-palette-installer -n prod-node-red-system

# View installation logs
kubectl logs job/prod-node-red-palette-installer -n prod-node-red-system
```

#### Flow Persistence Issues
```bash
# Check PVC status
kubectl get pvc prod-node-red-data -n prod-node-red-system

# Check storage class
kubectl get storageclass
```

### n8n Issues

#### Database Connection
```bash
# Check n8n logs
kubectl logs deployment/prod-n8n -n prod-n8n-system

# Check database configuration
kubectl describe deployment prod-n8n -n prod-n8n-system
```

#### Webhook Access
```bash
# Test webhook endpoint
curl -X POST https://n8n.{domain}/webhook-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

## Integration Examples

### Home Assistant + Node-RED
```javascript
// Node-RED flow example
[
  {
    "id": "ha-sensor",
    "type": "ha-sensor",
    "name": "Temperature Sensor",
    "server": "home-assistant",
    "entityid": "sensor.temperature"
  }
]
```

### Prometheus Monitoring + n8n
```javascript
// n8n workflow example
{
  "nodes": [
    {
      "name": "Prometheus Alert",
      "type": "webhook",
      "webhookId": "prometheus-alerts"
    }
  ]
}
```

## Best Practices

### Security
- Use **network policies** to isolate services
- Configure **RBAC** for service accounts
- Enable **authentication** for external access

### Performance
- Use **NFS storage** for shared access
- Configure **resource limits** based on workload
- Monitor **resource usage** with Prometheus

### Maintenance
- **Backup flows/workflows** regularly
- **Update palette packages** periodically
- **Monitor logs** for errors

## Advanced Configuration

### Custom Node-RED Settings
```hcl
# Future enhancement - custom settings.js
service_overrides = {
  node_red = {
    custom_settings = {
      ui_port = 1880
      debug_max_length = 1000
      function_global_context = true
    }
  }
}
```

### n8n Database Integration
```hcl
# Future enhancement - PostgreSQL integration
service_overrides = {
  n8n = {
    database = {
      type = "postgresql"
      host = "postgres.database.svc.cluster.local"
      port = 5432
      database = "n8n"
    }
  }
}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to automation services.

### Areas for Contribution
- **Documentation**: Homelab-specific examples
- **Features**: Custom configurations and integrations
- **Testing**: Additional test scenarios
- **Security**: Enhanced security configurations
