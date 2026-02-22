# Grafana Dashboard Update - 2026-02-22

## Dashboard Revisions Review

### Need Updates (Low Revisions - Check for Latest)

| Dashboard | ID | Current Rev | Status | Notes |
|-----------|----|-------------|---------|-------|
| Kubernetes Cluster Monitoring | 31556 | 1 | ⚠️ Check | Newer revisions likely available |
| K8s Cluster Prometheus | 6417 | 1 | ⚠️ Check | Should verify latest version |
| K8s Persistent Volumes | 13646 | 2 | ⚠️ Check | May have updates |
| K8s Deployments | 8588 | 1 | ⚠️ Check | Should verify latest version |
| Prometheus Stats | 2 | 2 | ⚠️ Check | Very old dashboard, check alternatives |
| Alertmanager | 15157 | 1 | ⚠️ Check | May have updates |
| Traefik | 4475 | 5 | ✅ Good | Recent revision |
| CoreDNS | 15762 | 1 | ⚠️ Check | Should verify latest version |
| MetalLB | 13332 | 1 | ⚠️ Check | Should verify latest version |
| Consul | 10642 | 1 | ⚠️ Check | May have updates |
| Vault | 12904 | 2 | ⚠️ Check | Should verify latest version |
| Redis | 763 | 4 | ✅ Good | Recent revision |
| Loki Kubernetes | 13639 | 2 | ⚠️ Check | May have updates |
| Loki Operational | 14055 | 1 | ⚠️ Check | Should verify latest version |
| Node Exporter | 1860 | 39 | ✅ Excellent | Very recent |

### Dashboard IDs That May Need Verification

Based on comments in the file, these were previously wrong and should be verified:
- **Alertmanager** (15157) - Was OCR Telemetry, fixed
- **CoreDNS** (15762) - Was KUSAMA validators, fixed
- **MetalLB** (13332) - Was Discourse, fixed

## Recommended New Dashboards

Based on your deployed services, here are dashboards to add:

### Authelia (SSO/2FA)
- **Grafana.com**: Search for "Authelia" dashboards
- **Alternative**: Authelia includes built-in metrics on port 9959
  - Location: `examples/grafana-dashboards/simple.json` in Authelia repo
- **Metrics to monitor**:
  - Authentication requests/success/failure rates
  - Session statistics
  - 2FA method usage
  - LDAP/OIDC integration metrics
  - Redis session storage performance

### Headlamp (Kubernetes Dashboard)
- **Grafana.com**: Search for "Headlamp" or "Kubernetes Dashboard"
- **Alternative**: Use general Kubernetes deployment dashboards
- **Grafana IDs to investigate**:
  - 7249 (Kubernetes Deployment Views)
  - 3131 (Kubernetes Cluster Views)
- **Metrics to monitor**:
  - User authentication metrics (if LDAP integrated)
  - API server latency
  - Resource usage by namespace

### KubeVirt (Virtual Machines)
- **Grafana.com**: Search for "KubeVirt" or "kubevirt"
- **Expected dashboard ID**: Likely in the 15000+ range (CNCF project)
- **Metrics to monitor**:
  - VM CPU/Memory usage per virtual machine
  - Virtual Machine Instance (VMI) health status
  - Containerized Data Importer (CDI) progress
  - virt-launcher pod metrics
  - Live migration status (if HA enabled)
- **Alternative**: Use libvirt/KVM dashboards and adapt for KubeVirt

### Portainer (Container Management)
- **Grafana.com**: Search for "Portainer"
- **Challenge**: Portainer doesn't expose Prometheus metrics natively
- **Workarounds**:
  1. Monitor Portainer via cAdvisor/container metrics
  2. Use generic Docker container dashboards (ID: 179, 893, 3062)
  3. Monitor Portainer's backend API response times
- **Recommended**: Use existing container dashboards instead

### Home Assistant (IoT Automation)
- **Grafana.com**: Search for "Home Assistant"
- **Expected IDs**: Multiple community dashboards available
- **Integration**: Requires Home Assistant Prometheus integration
- **Metrics to monitor**:
  - Sensor states and changes
  - Automation execution rates
  - Database size (recorder)
  - WebSocket connections
  - Add-on resource usage

### openHAB (Home Automation)
- **Grafana.com**: Search for "openHAB"
- **Note**: Less common than Home Assistant
- **Alternative**: Use generic IoT/mqtt dashboards

### Node-RED (Workflow Automation)
- **Grafana.com**: Search for "Node-RED" or "nodered"
- **Expected IDs**: Community dashboards exist
- **Metrics to monitor**:
  - Flow execution statistics
  - Node execution times
  - HTTP request/response rates
  - MQTT message throughput

### n8n (Workflow Automation)
- **Status**: No official dashboard (commented out in config)
- **Grafana.com**: Search community dashboards
- **Alternative**: Monitor via Node.js/process metrics
- **Metrics to monitor**:
  - Workflow execution success/failure
  - Webhook response times
  - Queue processing rates
  - Database connection pool stats

### Homebridge (HomeKit Gateway)
- **Grafana.com**: Search for "Homebridge"
- **Note**: Node.js application - use Node.js dashboards
- **Metrics to monitor**:
  - Accessory status
  - MQTT/HTTP request rates
  - Plugin resource usage

## Recommended Dashboard Revisions to Update

Check these Grafana.com URLs for latest revisions:

1. **Node Exporter (1860)**: Currently rev 39 - Check for rev 40+
2. **Traefik (4475)**: Currently rev 5 - Check for rev 6+
3. **Redis (763)**: Currently rev 4 - Check for rev 5+

## Missing Service Dashboards Priority

### High Priority (Critical Infrastructure)
1. **KubeVirt** - New VM management service
2. **Authelia** - SSO authentication for multiple services

### Medium Priority (Enhanced Visibility)
3. **Home Assistant** - If actively used for IoT
4. **Node-RED** - If actively used for automation workflows
5. **n8n** - If actively used for workflow automation

### Low Priority (Nice to Have)
6. **Headlamp** - Dashboard UI (less critical to monitor)
7. **Portainer** - Already have container metrics via cAdvisor
8. **openHAB** - If Home Assistant is primary
9. **Homebridge** - Node.js metrics sufficient

## Next Steps

1. Visit https://grafana.com/grafana/dashboards/ and search for each service
2. Check dashboard revisions for existing dashboards
3. Test dashboards in development environment before production
4. Create custom dashboards for services without official ones
5. Document custom dashboard creation process

## Dashboard Testing Checklist

Before deploying to production:
- [ ] Verify dashboard loads without errors
- [ ] Confirm all queries return data
- [ ] Check dashboard refresh performance (<5s)
- [ ] Validate time range selections work correctly
- [ ] Test with different data sources (Prometheus, Loki)
- [ ] Ensure dashboard works on mobile/responsive
- [ ] Verify all panels have proper descriptions
- [ ] Check for any deprecated query syntax
