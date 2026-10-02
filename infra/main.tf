terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.project_id
}

locals {
  # Cuenta de servicio por defecto de App Engine (existe cuando se crea la app).
  appspot_sa = "${var.project_id}@appspot.gserviceaccount.com"
  repo       = "${var.github_usuario}/${var.github_repo}"

  apis = [
    "appengine.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ]

  # Permisos que Cloud Build necesita para construir la app (el error del despliegue manual).
  appspot_roles = [
    "roles/cloudbuild.builds.builder",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
  ]

  # Permisos de la cuenta que despliega desde GitHub Actions.
  deployer_roles = [
    "roles/appengine.appAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

# 1) APIs del proyecto
resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  service            = each.value
  disable_on_destroy = false
}

# 2) La aplicacion App Engine (equivale al App Service Plan + Web App).
#    La region no se puede cambiar despues.
resource "google_app_engine_application" "app" {
  location_id = var.region_appengine
  depends_on  = [google_project_service.apis]
}

resource "google_project_iam_member" "appspot" {
  for_each   = toset(local.appspot_roles)
  project    = var.project_id
  role       = each.value
  member     = "serviceAccount:${local.appspot_sa}"
  depends_on = [google_app_engine_application.app]
}

# 3) Cuenta de servicio que usara el pipeline (reemplaza al publish profile)
resource "google_service_account" "deployer" {
  account_id   = "github-deployer"
  display_name = "Despliegue desde GitHub Actions"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "deployer" {
  for_each = toset(local.deployer_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.deployer.email}"
}

# Para desplegar, la cuenta debe poder "actuar como" la cuenta de App Engine.
resource "google_service_account_iam_member" "deployer_actas" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${local.appspot_sa}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
  depends_on         = [google_app_engine_application.app]
}

# 4) Federacion de identidad: GitHub presenta un token, GCP lo valida. Sin secretos.
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Solo tu repositorio puede usar esta federacion.
  attribute_condition = "assertion.repository == \"${local.repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.repo}"
}
