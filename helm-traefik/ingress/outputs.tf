output "middleware_used" {
  description = "Middleware applied to dashboard authentication"
  value = {
    type        = "centralized"
    middlewares = var.dashboard_middleware
  }
}
