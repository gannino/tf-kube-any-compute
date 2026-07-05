# ============================================================================
# S3 CSI - Local Configuration with 5-Level Override Hierarchy
# ============================================================================

# Common labels for all resources
locals {
  common_labels = {
    managed-by  = "terraform"
    component   = "s3-csi"
    provisioner = "yandex-cloud"
  }
}

# Module configuration with override hierarchy (Level 1-3)
locals {
  module_config = {
    name          = coalesce(try(var.service_overrides.helm_config.name, null), var.name, "s3-csi")
    namespace     = coalesce(try(var.service_overrides.helm_config.namespace, null), var.namespace, "s3-csi-system")
    chart_name    = coalesce(try(var.service_overrides.helm_config.chart_name, null), var.chart_name, "csi-s3")
    chart_repo    = var.chart_repo # OCI chart URL typically not overridden
    chart_version = var.chart_version
  }
}

# Helm configuration with override hierarchy
locals {
  helm_config = {
    timeout          = coalesce(try(var.service_overrides.helm_config.timeout, null), var.helm_timeout, 600)
    disable_webhooks = coalesce(try(var.service_overrides.helm_config.disable_webhooks, null), var.helm_disable_webhooks, false)
    skip_crds        = coalesce(try(var.service_overrides.helm_config.skip_crds, null), var.helm_skip_crds, false)
    replace          = coalesce(try(var.service_overrides.helm_config.replace, null), var.helm_replace, false)
    force_update     = coalesce(try(var.service_overrides.helm_config.force_update, null), var.helm_force_update, false)
    cleanup_on_fail  = coalesce(try(var.service_overrides.helm_config.cleanup_on_fail, null), var.helm_cleanup_on_fail, false)
    wait             = coalesce(try(var.service_overrides.helm_config.wait, null), var.helm_wait, false)
    wait_for_jobs    = coalesce(try(var.service_overrides.helm_config.wait_for_jobs, null), var.helm_wait_for_jobs, false)
  }
}

# S3 configuration with override hierarchy
locals {
  s3_config = {
    endpoint          = coalesce(try(var.service_overrides.s3_endpoint, null), var.s3_endpoint)
    access_key_id     = coalesce(try(var.service_overrides.s3_access_key_id, null), var.s3_access_key_id)
    secret_access_key = coalesce(try(var.service_overrides.s3_secret_access_key, null), var.s3_secret_access_key)
    bucket            = coalesce(try(var.service_overrides.s3_bucket, null), var.s3_bucket)
    region            = coalesce(try(var.service_overrides.s3_region, null), var.s3_region, "ru-central1")
  }
}

# Storage class configuration with override hierarchy
locals {
  storage_config = {
    name                   = coalesce(try(var.service_overrides.storage_class_name, null), var.storage_class_name, "csi-s3")
    mounter                = coalesce(try(var.service_overrides.mounter, null), var.mounter, "geesefs")
    mounter_options        = coalesce(try(var.service_overrides.mounter_options, null), var.mounter_options, "--memory-limit=1000 --dir-mode=0777 --file-mode=0666")
    set_as_default         = coalesce(try(var.service_overrides.set_as_default_storage_class, null), var.set_as_default_storage_class, false)
    reclaim_policy         = coalesce(try(var.service_overrides.reclaim_policy, null), var.reclaim_policy, "Retain")
    volume_binding_mode    = coalesce(try(var.service_overrides.volume_binding_mode, null), var.volume_binding_mode, "Immediate")
    allow_volume_expansion = coalesce(try(var.service_overrides.allow_volume_expansion, null), var.allow_volume_expansion, false)
  }
}

# Resource configuration with override hierarchy
locals {
  resource_config = {
    limits = {
      cpu    = coalesce(try(var.service_overrides.helm_config.resource_limits.limits.cpu, null), var.cpu_limit, "200m")
      memory = coalesce(try(var.service_overrides.helm_config.resource_limits.limits.memory, null), var.memory_limit, "256Mi")
    }
    requests = {
      cpu    = coalesce(try(var.service_overrides.helm_config.resource_limits.requests.cpu, null), var.cpu_request, "50m")
      memory = coalesce(try(var.service_overrides.helm_config.resource_limits.requests.memory, null), var.memory_request, "64Mi")
    }
  }
}

# Limit range configuration
locals {
  limit_range_config = {
    enabled              = var.limit_range_enabled
    container_max_cpu    = coalesce(var.limit_range_container_max_cpu, local.resource_config.limits.cpu)
    container_max_memory = coalesce(var.limit_range_container_max_memory, local.resource_config.limits.memory)
    pvc_max_storage      = var.limit_range_pvc_max_storage
    pvc_min_storage      = var.limit_range_pvc_min_storage
  }
}

# Secret configuration
locals {
  secret_config = {
    name   = coalesce(try(var.service_overrides.secret_name, null), var.secret_name, "csi-s3-secret")
    create = var.create_secret
  }
}

# Template values for Helm chart (merges all overrides)
locals {
  template_values = merge(
    {
      # S3 configuration
      secret = {
        accessKeyID     = local.s3_config.access_key_id
        secretAccessKey = local.s3_config.secret_access_key
        endpoint        = local.s3_config.endpoint
        region          = local.s3_config.region
      }

      # CSI driver configuration
      csiS3 = {
        mounter = local.storage_config.mounter
        options = local.storage_config.mounter_options
      }

      # Storage class configuration
      storageClass = {
        name                 = local.storage_config.name
        bucket               = local.s3_config.bucket
        reclaimPolicy        = local.storage_config.reclaim_policy
        volumeBindingMode    = local.storage_config.volume_binding_mode
        allowVolumeExpansion = local.storage_config.allow_volume_expansion
        isDefaultClass       = local.storage_config.set_as_default
      }

      # Resource limits
      resources = {
        limits = {
          cpu    = local.resource_config.limits.cpu
          memory = local.resource_config.limits.memory
        }
        requests = {
          cpu    = local.resource_config.requests.cpu
          memory = local.resource_config.requests.memory
        }
      }

      # Architecture
      arch = var.cpu_arch
    },
    try(var.service_overrides.template_values, {})
  )
}
