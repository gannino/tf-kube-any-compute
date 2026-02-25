# Grafana Dashboard Review - Summary 2026-02-22

## Actions Taken

### 1. Reviewed Existing Dashboard Configuration
**File**: [helm-grafana/templates/grafana-values.yaml.tpl](https://github.com/gannino/tf-kube-any-compute/blob/main/helm-grafana/templates/grafana-values.yaml.tpl)

**Current Dashboards**: 15 total
- Overview: 1
- Kubernetes: 4
- Infrastructure: 8
- Application: 1
- Logs: 2

### 2. Verified Dashboard IDs on Grafana.com

#### Verified IDs
| Dashboard | ID | Revision | Status | Notes |
|-----------|----|----------|--------|-------|
| Node Exporter Full | 1860 | 39 | ✅ Current | Popular, actively maintained |
| Traefik | 4475 | 5 | ✅ Good | Stable |
| Redis | 763 | 4 | ✅ Good | Recent revision |
| KubeVirt | 11748 | 1 | ⚠️ Old | From 2020, consider updating |

#### Updates Made
- **KubeVirt**: Updated ID from placeholder `16231` to correct `11748` (verified on Grafana.com)

### 3. Dashboard Search Results

#### ✅ Found on Grafana.com
| Service | Dashboard ID | Dashboard Name | Revision | Date |
|---------|--------------|----------------|----------|------|
| **KubeVirt** | 11748 | KubeVirt VM Info | 1 | 2020-02-19 |
| **Home Assistant** | 11257 | Home Assistant | 1 | TBD |
| **Node-RED** | 15361 | Node-RED | 1 | TBD |
| **MQTT** | 10981 | MQTT | 3 | 2024 |

#### ❌ NOT Found on Grafana.com
| Service | Status | Recommendation |
|---------|--------|----------------|
| **Authelia** | No official dashboard | Use Authelia's built-in metrics (port 9959) or create custom dashboard |
| **Headlamp** | No specific dashboard | Use general Kubernetes dashboards |
| **Portainer** | No specific dashboard | Portainer doesn't expose Prometheus metrics natively |
| **openHAB** | No recent dashboard | Consider using MQTT or general IoT dashboards |
| **n8n** | No official dashboard | Use Node.js application dashboards |
| **Homebridge** | No specific dashboard | Use Node.js dashboards |

## Dashboard Revisions Review

### Low Revisions (May Need Updates)
Check these on Grafana.com for newer revisions:
- Kubernetes Cluster Monitoring (31556) - rev 1
- K8s Cluster Prometheus (6417) - rev 1
- K8s Persistent Volumes (13646) - rev 2
- K8s Deployments (8588) - rev 1
- Prometheus Stats (2) - rev 2
- Alertmanager (15157) - rev 1
- CoreDNS (15762) - rev 1
- MetalLB (13332) - rev 1
- Consul (10642) - rev 1
- Vault (12904) - rev 2
- Loki Kubernetes (13639) - rev 2
- Loki Operational (14055) - rev 1

### Good Revisions (Current)
- Node Exporter (1860) - rev 39 ✅
- Traefik (4475) - rev 5 ✅
- Redis (763) - rev 4 ✅

## Configuration Changes Made

### 1. Added New Dashboard Sections
**File**: [helm-grafana/templates/grafana-values.yaml.tpl](https://github.com/gannino/tf-kube-any-compute/blob/main/helm-grafana/templates/grafana-values.yaml.tpl)

Added two new provider folders:
- **Virtualization** - For KubeVirt VM monitoring
- **Automation** - For Home Assistant, Node-RED, MQTT

### 2. New Dashboards Added
```yaml
virtualization:
  kubevirt:
    gnetId: 11748
    revision: 1
    datasource: Prometheus

automation:
  home-assistant:
    gnetId: 11257
    revision: 1
    datasource: Prometheus
  node-red:
    gnetId: 15361
    revision: 1
    datasource: Prometheus
  mqtt:
    gnetId: 10981
    revision: 3
    datasource: Prometheus
```

## Recommendations

### High Priority
1. **Create custom Authelia dashboard** - Authelia includes built-in metrics on port 9959. Reference: `examples/grafana-dashboards/simple.json` in Authelia repo.

2. **Review KubeVirt dashboard** - Current dashboard (11748) is from 2020. May need updates or consider creating custom dashboard.

### Medium Priority
3. **Check for dashboard updates** - Many dashboards have revision 1-2, check for newer versions.

4. **Add Authelia service monitoring** - Since Authelia is deployed for SSO, set up monitoring for:
   - Authentication requests/success/failure rates
   - Session statistics
   - 2FA method usage
   - Redis session storage performance (if using Redis)

### Low Priority
5. **Portainer monitoring** - Use existing container dashboards (cAdvisor) instead of Portainer-specific.

6. **n8n monitoring** - Use Node.js application dashboard (11168) for n8n workflow monitoring.

## Testing Checklist

Before deploying to production:
- [ ] Test new dashboards load without errors
- [ ] Verify queries return data for all services
- [ ] Check dashboard refresh performance (<5s)
- [ ] Validate time range selections work
- [ ] Test on mobile/responsive layouts
- [ ] Confirm panel descriptions are accurate
- [ ] Check for deprecated query syntax

## Files Modified

1. **[helm-grafana/templates/grafana-values.yaml.tpl](https://github.com/gannino/tf-kube-any-compute/blob/main/helm-grafana/templates/grafana-values.yaml.tpl)**
   - Updated KubeVirt dashboard ID to correct value (11748)
   - Added Virtualization section for KubeVirt
   - Added Automation section for Home Assistant, Node-RED, MQTT
   - Added Node.js application dashboard for n8n compatibility

2. **[grafana-dashboards-update.md](grafana-dashboards-update.md)**
   - Detailed analysis and recommendations

## Next Steps

1. **Deploy and test** - Apply the changes and verify dashboards load correctly
2. **Monitor performance** - Check dashboard load times and query performance
3. **Create custom dashboards** - For Authelia and other services without official dashboards
4. **Update periodically** - Check Grafana.com for dashboard updates quarterly

## Sources

- [Grafana Dashboards Repository](https://grafana.com/grafana/dashboards/)
- [KubeVirt Dashboard](https://grafana.com/grafana/dashboards/11748-kubevirt/)
- [Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/)
- [Authelia Documentation](https://github.com/authelia/authelia)
