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
- [041226] S3-compatible storage providers may not use regions | Evidence: QNAP NAS doesn't have AWS-style regions - must use empty string for region parameter
- [041226] Terraform templatefile uses tostring() (lowercase), not toString() | Evidence: Helm template failed with "Call to unknown function" error
- [041226] coalesce() treats empty string as falsy, use try() for optional empty values | Evidence: s3_region with empty string caused coalesce to fail with "no non-null arguments"
