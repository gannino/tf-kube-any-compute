# Task Board

## Current Branch Status

**Active branch**: `feature/add-rook-storage`
**Recent work**: Adding Rook Ceph distributed storage with CSI integration
**Commits ready**: 3 commits (n8n docs, CI Trivy fixes, Grafana Longhorn migration)

## Today

- [x] Fix Trivy CI/CD installation with robust error handling and fallback (3 commits)
- [ ] Push commits to remote (includes n8n docs, CI Trivy fixes, Grafana Longhorn migration)
- [ ] Investigate and fix Grafana dashboard provisioning issue (dashboards exist but EOF errors in logs)
- [ ] Verify raspberrypi2 node-exporter visibility in Grafana dashboards
- [ ] CI/CD verification: Verify Trivy scan passes with new installation method

## This Week

- [ ] Decide on moving Grafana/Alertmanager to Longhorn (COMPLETED: Grafana migrated, others pending)

## Backlog

-

## Done

- [070526] **COMPLETE**: Fixed Trivy CI/CD installation (3 commits)
  - Root cause: Official Trivy v0.72.0 install script reports success but doesn't install binary
  - Solution: Use direct binary download as primary method (skip buggy install script)
  - Updated TRIVY_VERSION: 0.50.0 → 0.72.0
- [042026] **COMPLETE**: Fixed Grafana storage migration from HostPath to Longhorn
- [042026] **COMPLETE**: Resolved Grafana permission issues after cluster restart
- [042026] **COMPLETE**: Cleaned up 6 orphaned PVs from previous Grafana deployments
- [042026] **COMPLETE**: Verified cluster health and node-exporter status (all nodes working)
- [042026] **COMPLETE**: Updated Grafana storage class in terraform.tfvars
- [041726] **COMPLETE**: Fixed CI/CD Trivy installation (curl instead of wget, fail-fast behavior)
- [041726] **COMPLETE**: Documented n8n task runners feature (architecture, usage, troubleshooting)
- [041726] **COMPLETE**: Fixed n8n external task runner mode (broker binding, TCP health checks)
- [041426] **COMPLETE**: Fixed Traefik plugins-storage PVC issue (removed unnecessary PVC - plugins use emptyDir)
- [041426] **COMPLETE**: Fixed Authelia storage PVC (enabled persistence in Helm values)
- [041426] **COMPLETE**: Cleaned up 2 orphaned PVCs with detached Longhorn volumes
- [041426] **COMPLETE**: Cleaned up 19 Released PVs from NFS→Longhorn migration
- [041426] **VERIFIED**: All 19 PVs now Bound and actively used by services
- [041426] **DISCUSSED**: Risks of moving Loki/Grafana/Alertmanager from HostPath to Longhorn
- [041426] **COMPLETE**: README updated with comprehensive storage documentation (Longhorn, smart selection, examples)
- [041326] **COMPLETE**: CSI storage strategy review and implementation
- [041326] **MODIFIED**: locals.tf - smart primary_storage_class (Longhorn → NFS → HostPath)
- [041326] **MODIFIED**: locals.tf - new storage_classes mappings (block, shared)
- [041326] **MODIFIED**: terraform.tfvars.example - added longhorn = false
- [041326] **MODIFIED**: terraform.tfvars - set_as_default_storage_class = true
- [041326] **VERIFIED**: All services aligned with locals.tf storage configuration
- [041326] **VALIDATED**: terraform fmt + validate passed
- [041226] **PIVOT**: Abandoned S3 CSI (ARM64 incompatibility - x86_64 containers)
- [041226] **READY**: S3 CSI module configured for x86 deployment (future use)
- [032226] Fixed Rook Ceph ceph-cluster.tf template interpolation
