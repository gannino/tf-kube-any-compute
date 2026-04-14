# Task Board

## Today

- [x] Pre-commit Python expat fix completed
- [x] Architectural review completed - all aligned
- [x] README updated with comprehensive storage documentation
- [ ] Push commits to remote (2 commits ready)
- [ ] Decide on moving Grafana/Alertmanager to Longhorn (user asked about risks)

## This Week

## Backlog

-

## Done

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
