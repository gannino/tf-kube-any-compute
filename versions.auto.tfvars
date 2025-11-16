# ============================================================================
# Centralized Version Management
# ============================================================================
# This file contains all service versions for easy updates.
# Auto-loaded by Terraform (*.auto.tfvars pattern)
#
# Update Strategy:
# 1. Run: ./scripts/check-versions.sh --update-check
# 2. Review available updates
# 3. Update versions below
# 4. Test with: terraform plan
# 5. Apply with: terraform apply
# ============================================================================

service_overrides = {
  # ============================================================================
  # Helm Chart Versions
  # ============================================================================

  grafana = {
    chart_version = "10.1.4" # Latest: 10.1.4 (was 9.3.1)
  }

  portainer = {
    chart_version = "2.33.3" # Latest: 2.33.3 (was 1.0.69)
  }

  nfs_csi = {
    chart_version = "4.0.18" # Latest: 4.0.18 (was 4.0.17)
  }

  node_feature_discovery = {
    chart_version = "0.18.3" # Latest: 0.18.3 (was 0.17.3)
  }

  kube_state_metrics = {
    chart_version = "6.4.1" # Latest: 6.4.1 (was 5.15.2)
  }

  loki = {
    chart_version = "6.46.0" # Latest: 6.46.0 (was 6.16.0)
  }

  promtail = {
    chart_version = "6.17.1" # Latest: 6.17.1 (was 6.16.6)
  }

  node_red = {
    chart_version = "10.3.2" # Latest: 10.3.2 (was 0.35.0)
  }

  # ============================================================================
  # Docker Image Versions (Native Kubernetes Deployments)
  # ============================================================================
  # Note: Using 'latest' tag for automatic updates
  # To pin specific versions, uncomment and set image_version

  # home_assistant = {
  #   image_version = "2025.11.2"  # Latest stable
  # }

  # openhab = {
  #   image_version = "5.0.2"  # Latest stable (ARM64: 5.0.2-alpine)
  # }

  # homebridge = {
  #   image_version = "2025.11.0"  # Latest stable
  # }

  # n8n = {
  #   image_version = "1.120.3"  # Latest stable
  # }
}

# ============================================================================
# Version Update History
# ============================================================================
# 2025-01-16: Initial version management
#   - Updated Grafana: 9.3.1 → 10.1.4
#   - Updated Portainer: 1.0.69 → 2.33.3
#   - Updated NFS CSI: 4.0.17 → 4.0.18
#   - Updated Node Feature Discovery: 0.17.3 → 0.18.3
#   - Updated Kube-State-Metrics: 5.15.2 → 6.4.1
#   - Updated Loki: 6.16.0 → 6.46.0
#   - Updated Promtail: 6.16.6 → 6.17.1
#   - Updated Node-RED: 0.35.0 → 10.3.2
#   - openHAB: Using latest tag (5.0.2)
#   - Home Assistant: Using latest tag
#   - Homebridge: Using latest tag
#   - n8n: Using latest tag
