variable "resource_group_name" {
  description = "Name of the resource group where resources will be deployed"
  type        = string
}

variable "location" {
  description = "Location for all resources"
  type        = string
  default     = "australiaeast"
}

variable "azure_tag_prefix" {
  description = "Prefix for Azure Tags"
  type        = string
  default     = "NMW"
}

variable "app_service_plan_sku_name" {
  description = "The SKU of App Service Plan"
  type        = string
  default     = "B3"
}

variable "sql_collation" {
  description = "The database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "database_max_size" {
  description = "Maximum database size in bytes"
  type        = number
  default     = 268435456000
}

variable "database_tier" {
  description = "Database tier"
  type        = string
  default     = "Standard"
}

variable "database_sku_name" {
  description = "Database SKU name"
  type        = string
  default     = "S1"
}

variable "tags_by_resource" {
  description = "Tags to apply to specific resource types"
  type        = map(map(string))
  default     = {}
}

variable "configure_private_endpoints" {
  description = "Specifies whether Private Endpoints will be configured"
  type        = bool
  default     = false
}

variable "private_endpoints_vnet_name" {
  description = "Name of the Virtual Network for private endpoints"
  type        = string
  default     = "nmw-private-vnet"
}

variable "private_endpoints_vnet_cidr" {
  description = "CIDR block for the Virtual Network for private endpoints"
  type        = string
  default     = "10.200.0.0/16"
}

variable "private_endpoints_subnet_name" {
  description = "Name of the Subnet for private endpoints"
  type        = string
  default     = "nmw-privateendpoints-subnet"
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR block for the Subnet for private endpoints"
  type        = string
  default     = "10.200.1.0/24"
}

variable "app_subnet_name" {
  description = "Name of the Subnet for the application"
  type        = string
  default     = "nmw-app-subnet"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the Subnet for the application"
  type        = string
  default     = "10.200.2.0/27"
}

variable "private_web_app" {
  description = "Specifies whether the Web App will be private"
  type        = bool
  default     = false
}

variable "app_name" {
  description = "Application name prefix"
  type        = string
  default     = "nmw-app"
  
  validation {
    condition     = length(var.app_name) >= 2
    error_message = "The app_name must be at least 2 characters long."
  }
}

variable "web_app_portal_name" {
  description = "Override for Web App Portal name"
  type        = string
  default     = ""
}

variable "app_service_plan_name" {
  description = "Override for App Service Plan name"
  type        = string
  default     = ""
}

variable "sql_server_name" {
  description = "Override for SQL Server name"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Override for Database name"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Override for Key Vault name"
  type        = string
  default     = ""
}

variable "app_insights_name" {
  description = "Override for Application Insights name"
  type        = string
  default     = ""
}

variable "automation_account_name" {
  description = "Override for Automation Account name"
  type        = string
  default     = ""
}

variable "law_name" {
  description = "Override for Log Analytics Workspace name"
  type        = string
  default     = ""
}

variable "logs_law_name" {
  description = "Override for Logs Log Analytics Workspace name"
  type        = string
  default     = ""
}

variable "scripted_action_account_name" {
  description = "Override for Scripted Action Account name"
  type        = string
  default     = ""
}

variable "data_protection_storage_account_name" {
  description = "Override for Data Protection Storage Account name"
  type        = string
  default     = ""
}

variable "artifacts_location" {
  description = "The base URI where artifacts required by this template are located"
  type        = string
  default     = ""
}

variable "artifacts_location_sas_token" {
  description = "The sasToken required to access artifacts_location"
  type        = string
  default     = ""
  sensitive   = true
}
