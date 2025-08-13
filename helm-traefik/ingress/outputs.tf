output "traefik_dashboard_password" {
  description = "Traefik dashboard password"
  value       = local.dashboard_password
  sensitive   = true
}
