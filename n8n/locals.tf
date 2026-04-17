# ============================================================================
# NATIVE TERRAFORM N8N MODULE LOCALS - COMPUTED CONFIGURATION
# ============================================================================

locals {
  # Module configuration
  module_config = {
    name      = var.name
    namespace = var.namespace
  }

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "n8n"
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/component"  = "workflow-automation"
    "app.kubernetes.io/part-of"    = "homelab-automation"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # n8n configuration
  n8n_version = var.image_version
  n8n_host    = "n8n.${var.domain_name}"

  # Task runner configuration
  task_runner_enabled = var.enable_task_runners
  task_runner_name    = "${var.name}-task-runners"
  task_runner_version = var.task_runner_image_version

  # Task runner environment variables for n8n ConfigMap
  # Only include task runner config when enabled
  task_runner_config = var.enable_task_runners ? {
    # External mode: n8n runs task broker, task runners connect as separate pods
    N8N_RUNNERS_MODE = "external"
    # Task broker binding - expose to all interfaces for external task runners
    N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0"
    # Enable Python code execution in task runners
    N8N_NATIVE_PYTHON_RUNNER = "true"
  } : {}
}
