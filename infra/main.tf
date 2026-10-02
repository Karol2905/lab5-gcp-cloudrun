###############################################################################
# Laboratorio 5 - Infraestructura como codigo con Terraform
#
# Este archivo describe el ESTADO DESEADO de la infraestructura en Azure.
# No es un script: no dice "cree", dice "esto debe existir". Terraform compara
# lo declarado con lo que hay y calcula la diferencia.
#
# Se ejecuta desde su maquina con la sesion de Azure CLI (az login). No hace
# falta un Service Principal, que es justo lo que una suscripcion de estudiante
# normalmente no permite crear.
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # El estado queda en local (terraform.tfstate) porque trabajamos solos.
  # En un equipo real iria en un backend remoto (Azure Storage) con bloqueo,
  # para que dos personas no apliquen cambios a la vez.
}

provider "azurerm" {
  features {}

  # El proveedor toma las credenciales de la sesion de Azure CLI.
  subscription_id = var.subscription_id
}

# Sufijo aleatorio: el nombre de una Web App forma parte de un dominio publico
# (https://NOMBRE.azurewebsites.net) y debe ser unico en todo Azure.
resource "random_string" "sufijo" {
  length  = 5
  special = false
  upper   = false
}

locals {
  nombre_app = "app-notas-${var.usuario}-${random_string.sufijo.result}"

  etiquetas = {
    curso       = "Cloud Computing y DevOps"
    laboratorio = "05-app-service-cicd"
    estudiante  = var.usuario
    gestion     = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Grupo de recursos: el contenedor logico y, sobre todo, la unidad de borrado.
# Eliminar el grupo elimina todo lo de adentro; es la forma segura de no dejar
# recursos consumiendo credito.
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "rg-lab5-${var.usuario}"
  location = var.region
  tags     = local.etiquetas
}

# ---------------------------------------------------------------------------
# App Service Plan: la maquina (o la porcion de maquina) donde corren las apps.
# La SKU F1 es el plan gratuito: 1 GB de RAM, 60 minutos de CPU al dia, sin
# Always On, sin slots de despliegue, sin escalado. Suficiente para el curso.
# ---------------------------------------------------------------------------
resource "azurerm_service_plan" "plan" {
  name                = "plan-lab5-${var.usuario}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  os_type             = "Linux"
  sku_name            = var.sku_plan
  tags                = local.etiquetas
}

# ---------------------------------------------------------------------------
# La Web App: el sitio en si. Vive dentro del plan anterior.
# ---------------------------------------------------------------------------
resource "azurerm_linux_web_app" "app" {
  name                = local.nombre_app
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = local.etiquetas

  # El pipeline de GitHub Actions se autentica con el publish profile, que usa
  # autenticacion basica sobre el endpoint SCM. Azure la deja deshabilitada por
  # omision en suscripciones nuevas; si no se habilita aqui, el despliegue
  # falla con 401 Unauthorized.
  webdeploy_publish_basic_authentication_enabled = true
  ftp_publish_basic_authentication_enabled       = true

  site_config {
    # Always On no existe en F1: la aplicacion se duerme tras 20 minutos sin
    # trafico y la primera peticion despues tarda unos segundos.
    always_on = false

    # El plan gratuito solo ofrece trabajadores de 32 bits. Si se deja en false,
    # el apply falla.
    use_32_bit_worker = true

    application_stack {
      node_version = var.node_version
    }

    # Comando de arranque. Sin el, App Service intenta adivinar (busca
    # server.js, index.js o el script start) y no siempre acierta.
    app_command_line = "node src/server.js"
  }

  app_settings = {
    # El paquete ya trae node_modules construido y probado por el pipeline:
    # se despliega el artefacto, no el codigo fuente. Si se dejara en true,
    # Oryx volveria a instalar dependencias dentro de App Service y el
    # resultado podria no ser identico al que se probo.
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    NODE_ENV                       = "production"
    WEBSITE_RUN_FROM_PACKAGE       = "0"
  }
}
