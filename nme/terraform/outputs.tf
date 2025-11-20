output "app_url" {
  description = "URL of the deployed web application"
  value       = "https://${azurerm_windows_web_app.main.default_hostname}"
}

output "web_app_name" {
  description = "Name of the web app"
  value       = azurerm_windows_web_app.main.name
}

output "web_app_principal_id" {
  description = "Principal ID of the web app managed identity"
  value       = azurerm_windows_web_app.main.identity[0].principal_id
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_mssql_database.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "automation_account_name" {
  description = "Name of the main Automation Account"
  value       = azurerm_automation_account.main.name
}

output "automation_account_principal_id" {
  description = "Principal ID of the Automation Account managed identity"
  value       = azurerm_automation_account.main.identity[0].principal_id
}

output "scripted_action_account_name" {
  description = "Name of the Scripted Action Automation Account"
  value       = azurerm_automation_account.scripted_actions.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace for AVD"
  value       = azurerm_log_analytics_workspace.avd.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace for AVD"
  value       = azurerm_log_analytics_workspace.avd.name
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the Data Protection Storage Account"
  value       = azurerm_storage_account.data_protection.name
}
