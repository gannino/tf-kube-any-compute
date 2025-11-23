# 🔄 Version Updates Recommendations

## Current Status

### ⚠️ Services Using 'latest' Tag (5)

These services should be pinned to specific versions for production stability:

1. **Home Assistant** - `homeassistant/home-assistant:latest`
2. **Homebridge** - `homebridge/homebridge:latest`
3. **Node-RED** - `nodered/node-red:latest`
4. **n8n** - `n8nio/n8n:latest`

### ✅ Services with Pinned Versions

- **openHAB** - `openhab/openhab:4.2.1-alpine` ✅

---

## Recommended Updates

### Priority 1: Pin 'latest' Tags

#### Home Assistant
```hcl
# Current
image = "homeassistant/home-assistant:latest"

# Recommended
image = "homeassistant/home-assistant:2025.11.2"
```

**Latest Version**: 2025.11.2
**Update Path**: Update `helm-home-assistant/locals.tf`

#### Homebridge
```hcl
# Current
image = "homebridge/homebridge:latest"

# Recommended
image = "homebridge/homebridge:2025.11.0"
```

**Latest Version**: 2025.11.0
**Update Path**: Update `homebridge/locals.tf`

#### Node-RED
```hcl
# Current
image = "nodered/node-red:latest"

# Recommended
image = "nodered/node-red:4.1.1"
```

**Latest Version**: 4.1.1
**Update Path**: Update `helm-node-red/locals.tf`

#### n8n
```hcl
# Current
image = "n8nio/n8n:latest"

# Recommended
image = "n8nio/n8n:1.120.3"
```

**Latest Version**: 1.120.3
**Update Path**: Update `n8n/locals.tf`

---

## Helm Chart Updates

### Grafana
- **Current**: 9.3.1 (App: 12.1.0)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### Portainer
- **Current**: 1.0.69 (App: ce-latest-ee-2.27.9)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### NFS CSI Driver
- **Current**: 4.0.17 (App: 4.0.2)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### Loki
- **Current**: 6.16.0 (App: 3.1.1)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### Promtail
- **Current**: 6.16.6 (App: 3.0.0)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### Kube-State-Metrics
- **Current**: 5.15.2 (App: 2.10.1)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

### Node Feature Discovery
- **Current**: 0.17.3 (App: v0.17.3)
- **Status**: ✅ Recent version
- **Action**: Monitor for updates

---

## Update Strategy

### Phase 1: Pin Latest Tags (Low Risk)
1. Update Home Assistant to specific version
2. Update Homebridge to specific version
3. Update Node-RED to specific version
4. Update n8n to specific version

**Risk**: Low - Just pinning current versions
**Benefit**: Prevents unexpected breaking changes

### Phase 2: Test Updates (Medium Risk)
1. Test each service in development environment
2. Verify functionality and integrations
3. Check for breaking changes in release notes

### Phase 3: Production Rollout (Controlled)
1. Update one service at a time
2. Monitor for 24-48 hours
3. Rollback if issues detected

---

## Checking for Updates

### Manual Check
```bash
# Run version check script
./scripts/check-versions.sh

# Check with upstream comparison (requires helm repos)
./scripts/check-versions.sh --update-check
```

### Automated Monitoring
Consider setting up automated version checking:
- GitHub Dependabot (for Docker images)
- Renovate Bot (for Helm charts)
- Custom CI/CD pipeline

---

## Version Pinning Best Practices

### Docker Images
```hcl
# ❌ Bad - unpredictable
image = "service:latest"

# ✅ Good - predictable
image = "service:1.2.3"

# ✅ Better - with digest for immutability
image = "service:1.2.3@sha256:abc123..."
```

### Helm Charts
```hcl
# ✅ Good - pin chart version
chart_version = "1.2.3"

# ✅ Better - pin both chart and app version
chart_version = "1.2.3"
app_version   = "4.5.6"
```

---

## Breaking Changes to Watch

### Home Assistant
- Major version updates (2024.x → 2025.x) may have breaking changes
- Check release notes: https://www.home-assistant.io/blog/

### openHAB
- Version 4.x is stable
- Check for 4.3.x updates: https://github.com/openhab/openhab-distro/releases

### Homebridge
- Plugin compatibility may break between versions
- Test plugins after updates

### Node-RED
- Node.js version requirements may change
- Custom nodes may need updates

### n8n
- Workflow compatibility usually maintained
- Database migrations may be required

---

## Rollback Procedures

### Docker Image Rollback
```bash
# Update deployment with previous version
kubectl set image deployment/prod-home-assistant \
  home-assistant=homeassistant/home-assistant:2025.10.0 \
  -n prod-home-assistant-system

# Or rollback via Terraform
terraform apply -var="home_assistant_version=2025.10.0"
```

### Helm Chart Rollback
```bash
# List releases
helm list -n prod-grafana-system

# Rollback to previous version
helm rollback grafana -n prod-grafana-system

# Rollback to specific revision
helm rollback grafana 2 -n prod-grafana-system
```

---

## Update Checklist

- [ ] Review release notes for breaking changes
- [ ] Backup persistent data (PVCs)
- [ ] Test in development environment
- [ ] Update one service at a time
- [ ] Monitor logs after update
- [ ] Verify functionality
- [ ] Document any issues
- [ ] Update this document with findings

---

## Resources

- **Home Assistant Releases**: https://github.com/home-assistant/core/releases
- **openHAB Releases**: https://github.com/openhab/openhab-distro/releases
- **Homebridge Releases**: https://github.com/homebridge/homebridge/releases
- **Node-RED Releases**: https://github.com/node-red/node-red/releases
- **n8n Releases**: https://github.com/n8n-io/n8n/releases

---

**Last Updated**: 2025-01-16
**Next Review**: 2025-02-16 (Monthly)
