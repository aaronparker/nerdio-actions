terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# Partner Center tracking deployment
resource "azurerm_resource_group_template_deployment" "partner_tracking" {
  name                = "pid-8c1c30c0-3e0a-4655-9e05-51dea63a0e32-partnercenter"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  
  template_content = jsonencode({
    "$schema"        = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion   = "1.0.0.0"
    resources        = []
  })
}

# Log Analytics Workspace for App Insights
resource "azurerm_log_analytics_workspace" "logs" {
  name                = local.logs_law_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  
  tags = merge(
    try(var.tags_by_resource["Microsoft.OperationalInsights/workspaces"], {}),
    {}
  )
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  
  tags = merge(
    try(var.tags_by_resource["Microsoft.Insights/components"], {}),
    { displayName = "AppInsightsComponent" }
  )
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                          = local.sql_server_name
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  version                       = "12.0"
  administrator_login           = "sqladmin"
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = !var.configure_private_endpoints
  
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = merge(
    try(var.tags_by_resource["Microsoft.Sql/servers"], {}),
    { displayName = "SqlServer" }
  )
}

# Random password for SQL Server (temporary, should be managed by Key Vault in production)
resource "random_password" "sql_admin" {
  length  = 24
  special = true
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = local.database_name
  server_id      = azurerm_mssql_server.main.id
  collation      = var.sql_collation
  max_size_gb    = var.database_max_size / 1073741824 # Convert bytes to GB
  sku_name       = var.database_sku_name
  
  tags = merge(
    try(var.tags_by_resource["Microsoft.Sql/servers/databases"], {}),
    { displayName = "Database" }
  )
}

# SQL Firewall Rule (only if private endpoints are not configured)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.configure_private_endpoints ? 0 : 1
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Windows"
  sku_name            = var.app_service_plan_sku_name
  
  tags = try(var.tags_by_resource["Microsoft.Web/serverfarms"], {})
}

# Web App
resource "azurerm_windows_web_app" "main" {
  name                          = local.web_app_portal_name
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  service_plan_id               = azurerm_service_plan.main.id
  https_only                    = true
  public_network_access_enabled = !(var.configure_private_endpoints && var.private_web_app)
  virtual_network_subnet_id     = var.configure_private_endpoints ? azurerm_subnet.app[0].id : null
  
  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    always_on                         = true
    http2_enabled                     = true
    use_32_bit_worker                 = false
    ftps_state                        = "Disabled"
    minimum_tls_version               = "1.3"
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

    app_settings = {
      "AzureAd:Instance"                             = local.microsoft_login_uri
      "Deployment:AzureType"                         = data.azurerm_client_config.current.environment
      "Deployment:Region"                            = var.location
      "Deployment:KeyVaultName"                      = local.key_vault_name
      "Deployment:SubscriptionId"                    = data.azurerm_client_config.current.subscription_id
      "Deployment:SubscriptionDisplayName"           = data.azurerm_resource_group.main.name # Approximation
      "Deployment:TenantId"                          = data.azurerm_client_config.current.tenant_id
      "Deployment:ResourceGroupName"                 = data.azurerm_resource_group.main.name
      "Deployment:WebAppName"                        = local.web_app_portal_name
      "Deployment:AutomationAccountName"             = local.automation_account_name
      "Deployment:AutomationAccountAzInstalled"      = "True"
      "Deployment:AutomationEnabled"                 = "True"
      "Deployment:AzureTagPrefix"                    = var.azure_tag_prefix
      "Deployment:UpdaterRunbookRunAs"               = "nmwUpdateRunAs"
      "Deployment:LogAnalyticsWorkspace"             = azurerm_log_analytics_workspace.avd.id
      "Deployment:ScriptedActionAccount"             = azurerm_automation_account.scripted_actions.id
      "ApplicationInsights:InstrumentationKey"       = azurerm_application_insights.main.instrumentation_key
      "ApplicationInsights:ConnectionString"         = azurerm_application_insights.main.connection_string
      "DataProtection:Storage:Type"                  = "AzureBlobStorage"
      "DataProtection:Protect:KeyIdentifier"         = local.data_protection_key_uri
      "Deployment:SqlServerId"                       = azurerm_mssql_server.main.id
    }
  
  tags = try(var.tags_by_resource["Microsoft.Web/sites"], {})
}

# Storage Account for Data Protection
resource "azurerm_storage_account" "data_protection" {
  name                             = local.data_protection_storage_account_name
  location                         = var.location
  resource_group_name              = data.azurerm_resource_group.main.name
  account_tier                     = "Standard"
  account_replication_type         = "GRS"
  account_kind                     = "StorageV2"
  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public  = false
  shared_access_key_enabled        = true
  public_network_access_enabled    = !var.configure_private_endpoints
  
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Storage/storageAccounts"], {})
}

# Storage Container for Data Protection Keys
resource "azurerm_storage_container" "data_protection_keys" {
  name                  = local.data_protection_storage_blob_container
  storage_account_id    = azurerm_storage_account.data_protection.id
  container_access_type = "private"
}

# Storage Container for Locks
resource "azurerm_storage_container" "locks" {
  name                  = local.blob_lease_container
  storage_account_id    = azurerm_storage_account.data_protection.id
  container_access_type = "private"
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  enabled_for_deployment     = false
  public_network_access_enabled = !var.configure_private_endpoints
  
  network_acls {
    bypass         = "AzureServices"
    default_action = var.configure_private_endpoints ? "Deny" : "Allow"
  }
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_windows_web_app.main.identity[0].principal_id
    
    key_permissions = [
      "WrapKey",
      "UnwrapKey"
    ]
    
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }
  
  tags = try(var.tags_by_resource["Microsoft.KeyVault/vaults"], {})
}

# Key Vault Key for Data Protection
resource "azurerm_key_vault_key" "data_protection" {
  name         = local.data_protection_key_name
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "data_protection_storage_path" {
  name         = "DataProtection--Storage--Path"
  value        = "https://${azurerm_storage_account.data_protection.name}.blob.${local.storage_suffix}/${local.data_protection_storage_blob_container}/keys-${local.unique_str}.xml?${data.azurerm_storage_account_sas.data_protection.sas}"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "connection_string" {
  name         = "ConnectionStrings--DefaultConnection"
  value        = "Server=tcp:${azurerm_mssql_server.main.name}${local.sql_server_suffix},1433;Initial Catalog=${local.database_name};Persist Security Info=False;Authentication=Active Directory Service Principal;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "locks_container_sas_url" {
  name         = "Deployment--LocksContainerSasUrl"
  value        = "https://${azurerm_storage_account.data_protection.name}.blob.${local.storage_suffix}/${local.blob_lease_container}?${data.azurerm_storage_account_sas.locks.sas}"
  key_vault_id = azurerm_key_vault.main.id
}

# SAS Token for Data Protection Container
data "azurerm_storage_account_sas" "data_protection" {
  connection_string = azurerm_storage_account.data_protection.primary_connection_string
  https_only        = true
  signed_version    = "2017-11-09"
  
  resource_types {
    service   = false
    container = true
    object    = true
  }
  
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  
  start  = "2024-01-01T00:00:00Z"
  expiry = "2050-01-01T00:00:00Z"
  
  permissions {
    read    = true
    write   = true
    delete  = false
    list    = false
    add     = false
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# SAS Token for Locks Container
data "azurerm_storage_account_sas" "locks" {
  connection_string = azurerm_storage_account.data_protection.primary_connection_string
  https_only        = true
  signed_version    = "2017-11-09"
  
  resource_types {
    service   = false
    container = true
    object    = true
  }
  
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  
  start  = "2024-01-01T00:00:00Z"
  expiry = "2050-01-01T00:00:00Z"
  
  permissions {
    read    = true
    write   = true
    delete  = false
    list    = false
    add     = false
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# Automation Account for Scripted Actions
resource "azurerm_automation_account" "scripted_actions" {
  name                = local.scripted_action_account_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Basic"
  
  tags = try(var.tags_by_resource["Microsoft.Automation/automationAccounts"], {})
}

# Main Automation Account
resource "azurerm_automation_account" "main" {
  name                = local.automation_account_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Basic"
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = try(var.tags_by_resource["Microsoft.Automation/automationAccounts"], {})
}

# Automation Variables
resource "azurerm_automation_variable_string" "subscription_id" {
  name                    = "subscriptionId"
  resource_group_name     = data.azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  encrypted               = true
  description             = "Azure Subscription Id"
  value                   = data.azurerm_client_config.current.subscription_id
}

resource "azurerm_automation_variable_string" "web_app_name" {
  name                    = "webAppName"
  resource_group_name     = data.azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  encrypted               = true
  description             = "Web App Name"
  value                   = local.web_app_portal_name
}

resource "azurerm_automation_variable_string" "resource_group_name" {
  name                    = "resourceGroupName"
  resource_group_name     = data.azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  encrypted               = true
  description             = "Resource group"
  value                   = data.azurerm_resource_group.main.name
}

# Role Assignment - Automation Account Contributor on Web App
resource "azurerm_role_assignment" "automation_web_app" {
  scope                = azurerm_windows_web_app.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# Automation Runbook
resource "azurerm_automation_runbook" "update_run_as" {
  name                    = "nmwUpdateRunAs"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = true
  log_progress            = false
  description             = "Update using automation Run As account"
  runbook_type            = "PowerShell"
  
  publish_content_link {
    uri     = "${var.artifacts_location}scripts/nmw-update-run-as.ps1${var.artifacts_location_sas_token}"
    version = "1.0.0.0"
  }
  
  tags = try(var.tags_by_resource["Microsoft.Automation/automationAccounts/runbooks"], {})
}

# Log Analytics Workspace for AVD
resource "azurerm_log_analytics_workspace" "avd" {
  name                = local.law_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  
  tags = merge(
    try(var.tags_by_resource["Microsoft.OperationalInsights/workspaces"], {}),
    { NMW_OBJECT_TYPE = "LOG_ANALYTICS_WORKSPACE" }
  )
}

# Log Analytics Data Sources - Windows Events
resource "azurerm_log_analytics_datasource_windows_event" "system" {
  name                = "SystemEvents"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "System"
  event_types         = ["Error", "Warning"]
}

resource "azurerm_log_analytics_datasource_windows_event" "application" {
  name                = "ApplicationEvents"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "Application"
  event_types         = ["Error", "Warning"]
}

resource "azurerm_log_analytics_datasource_windows_event" "terminal_services_local" {
  name                = "TerminalServicesLocalSessionManagerOperational"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
  event_types         = ["Error", "Warning", "Information"]
}

resource "azurerm_log_analytics_datasource_windows_event" "terminal_services_remote" {
  name                = "TerminalServicesRemoteConnectionManagerAdmin"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin"
  event_types         = ["Error", "Warning", "Information"]
}

resource "azurerm_log_analytics_datasource_windows_event" "fslogix_operational" {
  name                = "MicrosoftFSLogixAppsOperational"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "Microsoft-FSLogix-Apps/Operational"
  event_types         = ["Error", "Warning", "Information"]
}

resource "azurerm_log_analytics_datasource_windows_event" "fslogix_admin" {
  name                = "MicrosoftFSLogixAppsAdmin"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  event_log_name      = "Microsoft-FSLogix-Apps/Admin"
  event_types         = ["Error", "Warning", "Information"]
}

# Log Analytics Performance Counters
resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_free_space" {
  name                = "perfcounter1"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "% Free Space"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_avg_queue_length" {
  name                = "perfcounter2"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Avg. Disk Queue Length"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_avg_sec_transfer" {
  name                = "perfcounter3"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Avg. Disk sec/Transfer"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_current_queue_length" {
  name                = "perfcounter4"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Current Disk Queue Length"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_reads_sec" {
  name                = "perfcounter5"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Disk Reads/sec"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_transfers_sec" {
  name                = "perfcounter6"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Disk Transfers/sec"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "disk_writes_sec" {
  name                = "perfcounter7"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "Disk Writes/sec"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "memory_available_mb" {
  name                = "perfcounter8"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Memory"
  instance_name       = "*"
  counter_name        = "Available Mbytes"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "memory_page_faults_sec" {
  name                = "perfcounter9"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Memory"
  instance_name       = "*"
  counter_name        = "Page Faults/sec"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "memory_pages_sec" {
  name                = "perfcounter10"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Memory"
  instance_name       = "*"
  counter_name        = "Pages/sec"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "memory_percent_committed_bytes" {
  name                = "perfcounter11"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Memory"
  instance_name       = "*"
  counter_name        = "% Committed Bytes In Use"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "physical_disk_avg_sec_read" {
  name                = "perfcounter12"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "PhysicalDisk"
  instance_name       = "*"
  counter_name        = "Avg. Disk sec/Read"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "physical_disk_avg_sec_write" {
  name                = "perfcounter13"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "PhysicalDisk"
  instance_name       = "*"
  counter_name        = "Avg. Disk sec/Write"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "processor_percent_processor_time" {
  name                = "perfcounter14"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Processor Information"
  instance_name       = "_Total"
  counter_name        = "% Processor Time"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "terminal_services_sessions" {
  name                = "perfcounter15"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Terminal Services"
  instance_name       = "*"
  counter_name        = "Active Sessions"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "user_input_delay" {
  name                = "perfcounter16"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "User Input Delay per Process"
  instance_name       = "*"
  counter_name        = "Max Input Delay"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "user_input_delay_session" {
  name                = "perfcounter17"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "User Input Delay per Session"
  instance_name       = "*"
  counter_name        = "Max Input Delay"
  interval_seconds    = 60
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "network_bytes_total" {
  name                = "perfcounter18"
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_name      = azurerm_log_analytics_workspace.avd.name
  object_name         = "Network Interface"
  instance_name       = "*"
  counter_name        = "Bytes Total/sec"
  interval_seconds    = 60
}
