# Knowledge Nominations

Candidate learnings from agents and sessions. The auditor reviews these
during each audit cycle and promotes valid ones to knowledge-base.md.

## Pending Nominations

### Terraform Template Best Practices

- [032226] Use complete template files for complex YAML instead of heredoc interpolation | Evidence: Rook Ceph ceph-cluster.tf - using `templatefile()` with full template eliminated interpolation errors
- [032226] Avoid `ttl_seconds_after_finished` on Kubernetes Jobs managed by Terraform | Evidence: Jobs were being recreated every apply because TTL deleted them, making Terraform see them as missing
- [032226] Dynamic node discovery via `data.kubernetes_nodes` prevents hardcoded node names | Evidence: Rook storage configuration now works on any cluster without hardcoding

### Rook Ceph Deployment Patterns

- [032226] Rook operator strips `directories` field from cluster-level storage spec | Evidence: Operator removes directories from live CephCluster spec, must use per-node configuration
- [032226] Mon pods may fail scheduling with anti-affinity errors on resource-constrained nodes | Evidence: Pending mon pod on raspberrypi3 with scheduler anti-affinity conflicts

### S3 CSI Driver Integration

- [041226] CSI drivers have specific volume mode requirements | Evidence: Rook Ceph requires block mode which hostpath CSI doesn't support, causing deployment failure
- [041226] S3-compatible storage providers may not have AWS-style regions | Evidence: QNAP NAS doesn't have regions - must use empty string for region parameter
- [041226] Terraform templatefile uses tostring() (lowercase), not toString() | Evidence: Helm template failed with "Call to unknown function" error
- [041226] coalesce() treats empty string as falsy, use try() for optional empty values | Evidence: s3_region with empty string caused coalesce to fail with "no non-null arguments"

### CI/CD Pipeline Security Tooling

- [041726] Security tools must fail-fast in CI, not gracefully degrade | Evidence: User rejected graceful degradation - "I don't like the error handling that try to hide that the tool is not working"
- [041726] wget is not guaranteed on GitHub Actions runners, use curl instead | Evidence: Trivy installation failed with "wget: command not found" - curl is always available
- [041726] GitHub release tarballs contain directory structures, extract specific files | Evidence: Trivy tarball has nested structure - must use `tar -xzf file.tar.gz -C /tmp/ binaryname`
- [041726] Use jq for GitHub API parsing instead of grep hacks | Evidence: `jq -r '.tag_name'` is more reliable than grep + sed for JSON parsing

### Storage Architecture & Permissions

- [042026] HostPath storage causes permission issues after cluster restart | Evidence: Grafana init container failed with "Permission denied" on /var/lib/grafana/pdf,png,csv - files persisted with wrong ownership
- [042026] Longhorn storage solves permission issues with fresh volumes | Evidence: Grafana migration to Longhorn eliminated init container failures - clean filesystem per PVC
- [042026] Terraform plan monitors configuration state, not runtime health | Evidence: `terraform plan` showed no changes even though Grafana was broken - monitors resources, not pod health
- [042026] Grafana init-chown-data container essential for HostPath, optional for Longhorn | Evidence: With HostPath, runs as root to fix permissions; with Longhorn, completes successfully as no-op
- [042026] Helm uninstall required before PVC deletion for clean migration | Evidence: User correctly insisted on Helm uninstall before deleting Grafana resources - prevents orphaned resources
- [042026] Orphaned PVs accumulate with HostPath Retain policy | Evidence: Found 6 orphaned Grafana PVs from previous deployments - manual cleanup required

### Helm Release Reliability (070626)

- [070626] Set `atomic=true` on every helm_release to prevent stale failed releases blocking re-applies | Evidence: New cluster apply hit "cannot re-use a name that is still in use" for consul/longhorn/metrics-server because prior failed apply left releases in `failed` status; `atomic=false` (provider default) was never overridden. `atomic=true` makes Helm auto-rollback on failure so the next apply is clean. `cleanup_on_fail=true` alone is insufficient — it's Terraform-side and unreliable when the failure is a `wait` timeout.
- [070626] Helm chart `args` value is APPENDED to `defaultArgs`, not replacing them | Evidence: helm-metrics-server passed `--secure-port=10250, --cert-dir=/tmp, --metric-resolution=15s` etc. as `args`, but chart v3.13.0 already injects these via `defaultArgs` template → duplicate flags in container args. Only pass args the chart doesn't already provide.

### Kubernetes-over-Tailscale (070626)

- [070626] Pin kubelet `--node-ip=<tailscale-ip>` BEFORE first cert generation or serving cert SANs won't include the Tailscale IP | Evidence: Naive install left kubelet pinned to LAN IP; cert SANs had only 192.168.x, not 100.x (Tailscale). API→kubelet calls (kubectl logs/exec/metrics) failed `x509: ... not 100.104.141.106`. Signature: only the control-plane node stays Ready because it heartbeats to localhost; all VPN-dependent workers flap to NotReady.
- [070626] Single control plane on a Tailscale-only cluster is a single point of failure | Evidence: `etcd-0` was the only etcd member; workers dropped in waves but the CP node never did. Run 3-node HA (dqlite) so one node's tailscaled death can't topple the cluster.
- [070626] Tailscale (WireGuard MTU 1280) + Calico VXLAN (default 1450) fragments large packets silently | Evidence: Small heartbeats passed but cert rotations and large ConfigMaps stalled. Fix: `kubectl patch felixconfiguration default --type merge -p '{"spec":{"vxlanMTU":1230}}'` (Tailscale 1280 − 50 encapsulation).
- [070626] Tailscale ACLs must explicitly allow microk8s ports: tcp:16443 (apiserver), tcp:10250 (kubelet), tcp:25000 (add-node), tcp:19001-19010 (dqlite HA) | Evidence: Default ACL is allow-all, but any custom ACL in admin console locks to explicit rules. Note microk8s uses 16443, not the standard 6443.

### StorageClass Configuration (070626)

- [070626] Derive every storage backend's `set_as_default` from a single `primary_storage_class` local to guarantee exactly one default | Evidence: hostpath and longhorn both ended up annotated `is-default-class=true` because their `set_as_default_storage_class` flags were computed independently. Kubernetes warns on multiple defaults and PVCs bind non-deterministically. Fix: `set_as_default_storage_class = local.primary_storage_class == "<name>"` for all three backends (nfs/hostpath/longhorn).

### Mixed-Architecture Cluster (070626)

- [070626] Mixed ARM64+AMD64 clusters require `auto_mixed_cluster_mode = true` or arch-scheduling wedges | Evidence: 3 Pi ARM64 + 2 amd64 microk8s cluster had scheduling failures because arch-aware scheduling wasn't enabled. Gotcha #3 in CLAUDE.md.
- [070626] Probe `timeoutSeconds: 1` (chart default) is too aggressive for ARM64/Pi TLS handshake cost | Evidence: metrics-server CrashLoopBackOff on Pi — liveness/readiness probes hit `https://<pod-ip>:10250` with 1s timeout, TLS+response took longer. Fix: override `livenessProbe`/`readinessProbe` with `timeoutSeconds: 10`. See helm-metrics-server probe_timeout_seconds variable.
