variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "Region por defecto del proveedor"
  type        = string
  default     = "us-central1"
}

variable "region_appengine" {
  description = "Region de App Engine (no se puede cambiar despues)"
  type        = string
  default     = "us-central"
}

variable "github_usuario" {
  description = "Usuario de GitHub dueno del repositorio"
  type        = string
}

variable "github_repo" {
  description = "Nombre del repositorio"
  type        = string
}
