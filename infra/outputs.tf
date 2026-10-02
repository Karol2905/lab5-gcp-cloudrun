output "proyecto" {
  value = var.project_id
}

output "url" {
  value = "https://${google_app_engine_application.app.default_hostname}"
}

output "cuenta_servicio" {
  value = google_service_account.deployer.email
}

output "wif_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}
