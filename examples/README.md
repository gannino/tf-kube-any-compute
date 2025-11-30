# Configuration Examples

Quick-start templates for common deployment scenarios.

## Quick Start Templates

### 🍓 Raspberry Pi Cluster
**File**: `quickstart-raspberry-pi.tfvars`
- ARM64 architecture
- Local hostPath storage
- Essential services only
- Resource-optimized for Pi

### 🏠 Home Lab with NFS
**File**: `quickstart-homelab.tfvars`
- NFS shared storage
- Full monitoring stack
- Consul + Vault
- Standard homelab setup

### 🏡 Home Automation Hub
**File**: `quickstart-home-automation.tfvars`
- Home Assistant
- Homebridge (HomeKit)
- Node-RED
- n8n workflows

### ☁️ Cloud Deployment
**File**: `quickstart-cloud.tfvars`
- EKS/GKE/AKS optimized
- Cloud storage classes
- Route53 DNS example
- Production-ready

### 🔀 Mixed Architecture
**File**: `quickstart-mixed-cluster.tfvars`
- ARM64 + AMD64 nodes
- Intelligent service placement
- Auto-detection enabled
- Performance optimization

## DNS Provider Examples

### Cloudflare
**File**: `dns-cloudflare.tfvars`
- DNS API token configuration
- Fast propagation (60s)

### AWS Route53
**File**: `dns-route53.tfvars`
- IAM credentials
- Cloud-native integration

## Authentication Examples

### LDAP Integration
**File**: `auth-ldap.tfvars`
- JumpCloud configuration
- Active Directory example
- Fallback to basic auth

## Usage

1. **Copy template to terraform.tfvars**:
   ```bash
   cp examples/quickstart-homelab.tfvars terraform.tfvars
   ```

2. **Customize for your environment**:
   ```bash
   vi terraform.tfvars
   ```

3. **Deploy**:
   ```bash
   make init
   make apply
   ```

4. **Enable authentication** (after first deployment):
   ```bash
   # Edit terraform.tfvars
   # Change: middleware_overrides.enabled = false
   # To:     middleware_overrides.enabled = true
   make apply
   ```

## Combining Examples

Mix and match configurations:

```bash
# Start with homelab base
cp examples/quickstart-homelab.tfvars terraform.tfvars

# Add Cloudflare DNS
cat examples/dns-cloudflare.tfvars >> terraform.tfvars

# Add LDAP auth
cat examples/auth-ldap.tfvars >> terraform.tfvars
```

## Test Configurations

See `../test-configs/` for CI/CD test configurations:
- `minimal.tfvars` - Bare minimum
- `raspberry-pi.tfvars` - Full Pi config
- `cloud.tfvars` - Cloud deployment
- `mixed-cluster.tfvars` - Mixed architecture
- `production.tfvars` - Production setup
