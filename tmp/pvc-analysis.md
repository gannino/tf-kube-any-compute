# PVC Cluster Analysis - Raw Data Patterns

## PVCs with `deletionTimestamp` (STUCK in Terminating - 11 total)

### Pattern Analysis

**Services WITH `helm.sh/resource-policy: keep` annotation:**
- ✗ prod-n8n-data (nfs-csi-safe) - STUCK
- ✗ prod-portainer (nfs-csi-safe) - STUCK

**Services WITHOUT annotation:**
- ✗ prod-authelia-storage (nfs-csi-safe) - STUCK
- ✗ prod-grafana (hostpath) - STUCK - **Has `meta.helm.sh/release-name`**
- ✗ prod-home-assistant (nfs-csi-safe) - STUCK
- ✗ prod-homebridge-data (nfs-csi-safe) - STUCK
- ✗ storage-prod-loki-0 (hostpath) - STUCK - **Has `ownerReferences` (StatefulSet)**
- ✗ prod-node-red-data (nfs-csi-safe) - STUCK
- ✗ prod-openhab-addons (nfs-csi-fast) - STUCK
- ✗ prod-openhab-conf (nfs-csi-fast) - STUCK
- ✗ prod-openhab-data (nfs-csi-fast) - STUCK

## PVCs WITHOUT `deletionTimestamp` (Healthy/Not stuck - 9 total)

**Services WITH `helm.sh/resource-policy: keep` annotation:**
- ✓ prod-traefik-certs (nfs-csi-safe) - NOT STUCK
- ✓ prod-portainer - STUCK (same annotation!)

**Services WITHOUT annotation:**
- ✓ data-prod-consul-stack-prod-consul-server-0 (nfs-csi-safe) - NOT STUCK
- ✓ data-prod-consul-stack-prod-consul-server-1 (nfs-csi-safe) - NOT STUCK
- ✓ data-prod-consul-stack-prod-consul-server-2 (nfs-csi-safe) - NOT STUCK
- ✓ alertmanager-prod-prometh-alert-kube-pr-alertmanager-db-alertmanager-prod-prometh-alert-kube-pr-alertmanager-0 (hostpath) - NOT STUCK
- ✓ prometheus-prod-prometh-alert-kube-pr-prometheus-db-prometheus-prod-prometh-alert-kube-pr-prometheus-0 (nfs-csi) - NOT STUCK
- ✓ prod-redis-data (nfs-csi-safe) - NOT STUCK
- ✓ prod-traefik-plugins-storage (nfs-csi-safe) - NOT STUCK

## CRITICAL FINDINGS

### 1. The `helm.sh/resource-policy: keep` annotation is NOT the primary cause

**Evidence**:
- prod-traefik-certs HAS the annotation but is NOT stuck
- prod-portainer HAS the annotation and IS stuck
- 9 out of 11 stuck PVCs do NOT have the annotation

### 2. Storage class is NOT the cause

**Evidence**:
- hostpath: 2 stuck (Grafana, Loki), 2 not stuck (Alertmanager)
- nfs-csi-safe: 6 stuck, 6 not stuck
- nfs-csi-fast: 3 stuck, 0 not stuck (sample size too small)

### 3. The key difference: What's still USING the PVC?

All PVCs have `kubernetes.io/pvc-protection` finalizer, which prevents deletion while a Pod is using the PVC.

**Hypothesis**: The PVCs are stuck because the pods/deployments/statefulsets that use them are not terminating properly, so the PVC protection finalizer won't let them delete.

## Next Analysis Required

We need to check the Pods/Deployments/StatefulSets in these namespaces to see:
1. Are there still pods running that are using these PVCs?
2. Are the pods stuck in terminating state too?
3. What's preventing the pods from terminating?

This would explain why:
- Consul PVCs are not stuck (their pods terminated cleanly)
- Prometheus/Alertmanager PVCs are not stuck (their pods terminated cleanly)
- Traefik plugins PVC is not stuck (its pod terminated cleanly)
- But Authelia, Grafana, N8N, etc. PVCs ARE stuck (their pods might not have terminated)

## Recommendation

Run this command to check pod status:

```bash
microk8s.kubectl get pods -A | grep -E "(Terminating|NAME)"
```

This will show us if the pods are stuck, which would explain why the PVCs can't delete (the PVC protection finalizer is working as designed).
