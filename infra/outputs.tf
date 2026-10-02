###############################################################################
# Salidas: los datos que el resto del laboratorio necesita despues del apply.
# Se consultan con: terraform output  o  terraform output -raw nombre_app
###############################################################################

output "nombre_app" {
  description = "Nombre de la Web App. Va en la variable AZURE_WEBAPP_NAME de GitHub."
  value       = azurerm_linux_web_app.app.name
}

output "url" {
  description = "URL publica del sitio"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "grupo_recursos" {
  description = "Grupo de recursos creado"
  value       = azurerm_resource_group.lab.name
}

output "comando_publish_profile" {
  description = "Comando listo para descargar el publish profile que se guarda como secreto en GitHub"
  value       = "az webapp deployment list-publishing-profiles --resource-group ${azurerm_resource_group.lab.name} --name ${azurerm_linux_web_app.app.name} --xml"
}
