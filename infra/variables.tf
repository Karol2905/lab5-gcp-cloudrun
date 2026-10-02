###############################################################################
# Variables de entrada.
#
# Una variable sin default es obligatoria: Terraform la pide o falla. Con
# default, el valor se puede omitir. Los valores concretos van en
# terraform.tfvars, que NO se versiona (puede traer datos de la suscripcion).
###############################################################################

variable "subscription_id" {
  description = "Id de la suscripcion de Azure. Se obtiene con: az account show --query id -o tsv"
  type        = string
}

variable "usuario" {
  description = "Identificador corto del estudiante; se usa en los nombres de los recursos (solo minusculas y numeros)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.usuario))
    error_message = "Use entre 3 y 12 caracteres, solo minusculas y numeros."
  }
}

variable "region" {
  description = "Region de Azure donde se crean los recursos"
  type        = string
  default     = "eastus2"
}

variable "sku_plan" {
  description = "SKU del App Service Plan. F1 es la capa gratuita."
  type        = string
  default     = "F1"
}

variable "node_version" {
  description = "Version de Node.js del runtime de App Service"
  type        = string
  default     = "22-lts"
}
