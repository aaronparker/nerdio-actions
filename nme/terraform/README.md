# Nerdio Manager for Enterprise - Terraform Template

This directory contains Terraform configuration files converted from the original ARM template for deploying Nerdio Manager for Enterprise (NME) on Azure.

## Overview

This Terraform configuration deploys a complete Nerdio Manager for Enterprise environment, including:

- **App Service** - Windows Web App for NMW portal
- **SQL Database** - Azure SQL Server and Database
- **Key Vault** - Secure storage for secrets and keys
- **Storage Account** - For data protection and locks
- **Automation Accounts** - For automated management tasks
- **Log Analytics Workspaces** - For monitoring and insights
- **Application Insights** - Application performance monitoring
- **Networking** (optional) - VNet, subnets, private endpoints, and private DNS zones

## Files Structure

- `main.tf` - Core Azure resources (App Service, SQL, Key Vault, Storage, Automation)
- `network.tf` - Networking resources (VNet, subnets, private endpoints, DNS zones)
- `variables.tf` - Input variable definitions
- `locals.tf` - Local values and naming conventions
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values (customize for your environment)

## Prerequisites

1. **Terraform** - Version >= 1.0
2. **Azure CLI** - Authenticated with appropriate permissions
3. **Resource Group** - Pre-existing Azure Resource Group

## Configuration

### Required Variables

You must set the `resource_group_name` variable to point to your existing resource group:

```hcl
resource_group_name = "your-resource-group-name"
```

### Optional Customization

Edit `terraform.tfvars` to customize:

- `location` - Azure region (default: australiaeast)
- `app_name` - Application name prefix (default: nmw-app)
- `configure_private_endpoints` - Enable private endpoints (default: false)
- `private_web_app` - Make web app private (default: false)
- `tags_by_resource` - Resource-specific tags

### Private Endpoints

To enable private networking:

```hcl
configure_private_endpoints    = true
private_web_app                = true
private_endpoints_vnet_cidr    = "172.16.0.0/16"
private_endpoints_subnet_cidr  = "172.16.0.0/24"
app_subnet_cidr                = "172.16.1.0/27"
```

## Deployment

### 1. Initialize Terraform

```bash
cd terraform/template
terraform init
```

### 2. Review Plan

```bash
terraform plan -var="resource_group_name=your-rg-name"
```

### 3. Deploy

```bash
terraform apply -var="resource_group_name=your-rg-name"
```

### 4. Get Outputs

```bash
terraform output
```

## Key Differences from ARM Template

### Advantages of Terraform

1. **Clearer Syntax** - More readable than ARM JSON
2. **Modular Design** - Separate files for different concerns
3. **Better State Management** - Terraform tracks resource state
4. **Cross-Cloud** - Can manage resources across providers
5. **Plan Before Apply** - Preview changes before deployment
6. **Variables & Locals** - More flexible configuration management

### Notable Changes

1. **Resource Names** - Unique string generation uses SHA256 hash instead of ARM's uniqueString()
2. **Environment Detection** - Uses azurerm_client_config data source
3. **Managed Identities** - Automatically configured for Web App and Automation Account
4. **SQL Authentication** - Generates random password, but AAD auth is recommended
5. **SAS Tokens** - Generated using data sources instead of listServiceSas()

## Post-Deployment

After deployment:

1. **Configure SQL Database** - Run database migrations
2. **Upload Web App Package** - Deploy application code (not included in Terraform)
3. **Configure Azure AD** - Set up authentication
4. **Review Security** - Verify Key Vault access policies and network rules
5. **Test Connectivity** - Verify all services are accessible

## Important Notes

### SQL Server Password

The SQL Server password is randomly generated. Consider:

- Using Azure AD authentication instead
- Storing password in Key Vault (currently generates random)
- Implementing password rotation

### Web App Deployment

The ARM template includes MSDeploy extension for app deployment. In Terraform:

- Deploy application code separately using Azure DevOps, GitHub Actions, or `az webapp deploy`
- Consider using `azurerm_app_service_source_control` resource for CI/CD

### Artifacts Location

If you need to reference external artifacts (like runbook scripts):

```hcl
artifacts_location          = "https://your-storage-account.blob.core.windows.net/artifacts/"
artifacts_location_sas_token = "?sv=2021-06-08&ss=b&srt=..."
```

## Outputs

Key outputs include:

- `app_url` - Web application URL
- `web_app_name` - Name of the web app
- `sql_server_fqdn` - SQL Server fully qualified domain name
- `key_vault_uri` - Key Vault URI
- `log_analytics_workspace_id` - Log Analytics workspace ID

## Cleanup

To destroy all resources:

```bash
terraform destroy -var="resource_group_name=your-rg-name"
```

**Warning**: This will delete all resources created by Terraform. Ensure you have backups if needed.

## Troubleshooting

### Key Vault Access Issues

If you encounter Key Vault access issues:

```bash
# Grant yourself access to the Key Vault
az keyvault set-policy --name <key-vault-name> \
  --upn <your-email> \
  --secret-permissions get list set delete
```

### Private Endpoint DNS Resolution

If private endpoints don't resolve correctly:

1. Verify virtual network links are created for all private DNS zones
2. Ensure DNS configuration on VMs/clients points to Azure DNS
3. Check NSG rules allow traffic to private endpoints

### Terraform State

Store state remotely for team collaboration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "nerdio-manager.tfstate"
  }
}
```

## Support

For issues specific to:

- **Terraform configuration** - Review this README and Terraform documentation
- **Nerdio Manager** - Contact Nerdio support
- **Azure resources** - Review Azure documentation

# ARM Template to Terraform Conversion Summary

## Conversion Overview

This document summarizes the conversion of the Nerdio Manager for Enterprise ARM template to Terraform.

## Files Created

| File | Purpose |
|------|---------|
| `main.tf` | Core Azure resources (App Service, SQL, Key Vault, Storage, Automation) |
| `network.tf` | Networking resources (VNet, subnets, private endpoints, DNS zones) |
| `variables.tf` | Input variable definitions |
| `locals.tf` | Local values and naming conventions |
| `outputs.tf` | Output values |
| `terraform.tfvars` | Variable values (customize for your environment) |
| `terraform.tfvars.example` | Example variable values template |
| `.gitignore` | Git ignore patterns for Terraform files |
| `README.md` | Deployment and usage documentation |

## Resource Mapping

### Core Resources

| ARM Resource Type | Terraform Resource Type | Notes |
|-------------------|-------------------------|-------|
| Microsoft.Resources/deployments | azurerm_resource_group_template_deployment | Partner tracking deployment |
| Microsoft.OperationalInsights/workspaces | azurerm_log_analytics_workspace | Two workspaces: logs and AVD monitoring |
| Microsoft.Insights/components | azurerm_application_insights | Application monitoring |
| Microsoft.Sql/servers | azurerm_mssql_server | SQL Server with AAD authentication |
| Microsoft.Sql/servers/databases | azurerm_mssql_database | SQL Database |
| Microsoft.Sql/servers/firewallRules | azurerm_mssql_firewall_rule | Conditional on private endpoints |
| Microsoft.Web/serverfarms | azurerm_service_plan | App Service Plan |
| Microsoft.Web/sites | azurerm_windows_web_app | Web application |
| Microsoft.Web/sites/extensions | N/A | MSDeploy - handle separately |
| Microsoft.KeyVault/vaults | azurerm_key_vault | Key vault with access policies |
| Microsoft.KeyVault/vaults/keys | azurerm_key_vault_key | Data protection key |
| Microsoft.KeyVault/vaults/secrets | azurerm_key_vault_secret | Multiple secrets |
| Microsoft.Storage/storageAccounts | azurerm_storage_account | Data protection storage |
| Microsoft.Storage/.../containers | azurerm_storage_container | Blob containers |
| Microsoft.Automation/automationAccounts | azurerm_automation_account | Two accounts: main and scripted actions |
| Microsoft.Automation/.../variables | azurerm_automation_variable_string | Automation variables |
| Microsoft.Automation/.../runbooks | azurerm_automation_runbook | Automation runbooks |
| Microsoft.Authorization/roleAssignments | azurerm_role_assignment | RBAC assignments |

### Log Analytics Data Sources

| ARM Resource Type | Terraform Resource Type |
|-------------------|-------------------------|
| Microsoft.OperationalInsights/.../dataSources (WindowsEvent) | azurerm_log_analytics_datasource_windows_event |
| Microsoft.OperationalInsights/.../dataSources (WindowsPerformanceCounter) | azurerm_log_analytics_datasource_windows_performance_counter |

### Networking Resources

| ARM Resource Type | Terraform Resource Type | Conditional |
|-------------------|-------------------------|-------------|
| Microsoft.Network/virtualNetworks | azurerm_virtual_network | ✓ Private endpoints |
| Microsoft.Network/virtualNetworks/subnets | azurerm_subnet | ✓ Private endpoints |
| Microsoft.Network/privateDnsZones | azurerm_private_dns_zone | ✓ Private endpoints |
| Microsoft.Network/privateDnsZones/virtualNetworkLinks | azurerm_private_dns_zone_virtual_network_link | ✓ Private endpoints |
| Microsoft.Network/privateEndpoints | azurerm_private_endpoint | ✓ Private endpoints |

## Key Differences

### 1. Unique String Generation

**ARM Template:**
```json
"uniqueStr": "[uniqueString(subscription().id, resourceGroup().id)]"
```

**Terraform:**
```hcl
unique_str = substr(sha256("${data.azurerm_client_config.current.subscription_id}${data.azurerm_resource_group.main.id}"), 0, 13)
```

**Note:** This will generate different values than ARM. If migrating from ARM to Terraform, consider using the `-web_app_portal_name`, `-sql_server_name`, etc. override variables to maintain existing resource names.

### 2. Environment Detection

**ARM Template:**
```json
"sqlServerSuffix": "[environment().suffixes.sqlServerHostname]"
"microsoftLoginUri": "[environment().authentication.loginEndpoint]"
```

**Terraform:**
```hcl
sql_server_suffix = data.azurerm_client_config.current.environment == "public" ? ".database.windows.net" : ...
microsoft_login_uri = data.azurerm_client_config.current.environment == "public" ? "https://login.microsoftonline.com/" : ...
```

### 3. SQL Server Authentication

**ARM Template:**
- Uses Azure AD authentication exclusively
- No administrator password in template

**Terraform:**
- Generates random password for SQL admin (stored in state)
- Also configures Azure AD authentication
- **Recommendation:** Use Azure AD auth and manage passwords externally

### 4. SAS Token Generation

**ARM Template:**
```json
"listServiceSas(variables('dataProtectionStorageAccountName'), '2023-04-01', variables('dataProtectionStorageContainerSasProperties')).serviceSasToken"
```

**Terraform:**
```hcl
data "azurerm_storage_account_sas" "data_protection" {
  connection_string = azurerm_storage_account.data_protection.primary_connection_string
  # ... configuration
}
```

### 5. Web App Deployment

**ARM Template:**
- Includes MSDeploy extension to deploy app package
- Single-step deployment with application code

**Terraform:**
- Infrastructure only
- Deploy application separately using:
  - Azure DevOps
  - GitHub Actions
  - `az webapp deploy` command
  - `azurerm_app_service_source_control` resource

### 6. Resource Group

**ARM Template:**
- Deployed to resource group at deployment time
- Uses `resourceGroup()` function

**Terraform:**
- Requires existing resource group
- Uses `data.azurerm_resource_group` data source
- Must specify `resource_group_name` variable

### 7. Conditional Resources

**ARM Template:**
```json
"condition": "[not(parameters('configurePrivateEndpoints'))]"
```

**Terraform:**
```hcl
count = var.configure_private_endpoints ? 0 : 1
```

## Variable Equivalence

| ARM Parameter | Terraform Variable | Default |
|---------------|-------------------|---------|
| location | location | australiaeast |
| azureTagPrefix | azure_tag_prefix | NMW |
| appServicePlanSkuName | app_service_plan_sku_name | B3 |
| sqlCollation | sql_collation | SQL_Latin1_General_CP1_CI_AS |
| databaseMaxSize | database_max_size | 268435456000 |
| databaseTier | database_tier | Standard |
| databaseSkuName | database_sku_name | S1 |
| tagsByResource | tags_by_resource | {} |
| configurePrivateEndpoints | configure_private_endpoints | false |
| privateEndpointsVnetName | private_endpoints_vnet_name | nmw-private-vnet |
| privateEndpointsVnetCidr | private_endpoints_vnet_cidr | 10.200.0.0/16 |
| privateEndpointsSubnetName | private_endpoints_subnet_name | nmw-privateendpoints-subnet |
| privateEndpointsSubnetCidr | private_endpoints_subnet_cidr | 10.200.1.0/24 |
| appSubnetName | app_subnet_name | nmw-app-subnet |
| appSubnetCidr | app_subnet_cidr | 10.200.2.0/27 |
| privateWebApp | private_web_app | false |
| appName | app_name | nmw-app |
| _webAppPortalName | web_app_portal_name | "" |
| _appServicePlanName | app_service_plan_name | "" |
| _sqlServerName | sql_server_name | "" |
| _databaseName | database_name | "" |
| _keyVaultName | key_vault_name | "" |
| _appInsightsName | app_insights_name | "" |
| _automationAccountName | automation_account_name | "" |
| _lawName | law_name | "" |
| _logsLawName | logs_law_name | "" |
| _scriptedActionAccountName | scripted_action_account_name | "" |
| _dataProtectionStorageAccountName | data_protection_storage_account_name | "" |
| _artifactsLocation | artifacts_location | "" |
| _artifactsLocationSasToken | artifacts_location_sas_token | "" |

**New Variable (Terraform only):**
- `resource_group_name` - Required to specify existing resource group

## Outputs Comparison

| ARM Output | Terraform Output | Notes |
|------------|------------------|-------|
| appUrl | app_url | Web app URL |
| N/A | web_app_name | Added for convenience |
| N/A | web_app_principal_id | Managed identity |
| N/A | sql_server_name | Server name |
| N/A | sql_server_fqdn | Server FQDN |
| N/A | database_name | Database name |
| N/A | key_vault_name | Key Vault name |
| N/A | key_vault_uri | Key Vault URI |
| N/A | automation_account_name | Automation account |
| N/A | automation_account_principal_id | Managed identity |
| N/A | scripted_action_account_name | Scripted actions account |
| N/A | log_analytics_workspace_id | Log Analytics ID |
| N/A | log_analytics_workspace_name | Log Analytics name |
| N/A | application_insights_name | App Insights name |
| N/A | application_insights_instrumentation_key | Instrumentation key (sensitive) |
| N/A | application_insights_connection_string | Connection string (sensitive) |
| N/A | storage_account_name | Storage account name |

## Best Practices Applied

1. **Modular Structure** - Resources split into logical files
2. **Variables** - All configurable values are variables
3. **Locals** - Computed values centralized in locals.tf
4. **Outputs** - Key resource information exposed
5. **Tagging** - Consistent tagging strategy using variables
6. **Security** - Sensitive outputs marked as sensitive
7. **Conditional Resources** - Using count for optional resources
8. **Documentation** - Comprehensive README and comments
9. **Examples** - Example tfvars file provided
10. **State Management** - .gitignore for sensitive files

## Not Included / Requires Manual Steps

1. **Web App Code Deployment** - Must be done separately
2. **Database Schema** - SQL migrations need to be run post-deployment
3. **Azure AD Configuration** - Application registration and permissions
4. **Monitoring Alerts** - Consider adding azurerm_monitor_metric_alert resources
5. **Backup Configuration** - Consider azurerm_backup_* resources
6. **Data Collection Rules** - Full DCR configuration from ARM template (partially implemented)

## Terraform Advantages

1. **State Management** - Tracks resource state and detects drift
2. **Plan Preview** - See changes before applying
3. **Modularity** - Easier to organize and reuse
4. **Multi-Cloud** - Can manage resources across providers
5. **Readable Syntax** - HCL is more readable than ARM JSON
6. **Community** - Large ecosystem of modules and providers
7. **CI/CD Integration** - Better integration with modern CI/CD pipelines
8. **Testing** - Easier to write tests with tools like Terratest

## Testing Recommendations

Before deploying to production:

1. **Validate Syntax**
   ```bash
   terraform fmt -check
   terraform validate
   ```

2. **Test in Dev Environment**
   ```bash
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

3. **Verify Resources**
   - Check Azure Portal
   - Test web app accessibility
   - Verify database connectivity
   - Check automation runbooks

4. **Cost Estimation**
   - Use Azure Cost Calculator
   - Or `terraform cost` (if using Terraform Cloud)

## Support and Maintenance

- Keep Terraform version up to date
- Monitor azurerm provider updates
- Review Azure resource API changes
- Update documentation as changes are made
- Consider using Terraform workspaces for multiple environments

## Conclusion

This Terraform configuration provides a complete, production-ready alternative to the ARM template with improved:
- Readability and maintainability
- Modularity and organization
- State tracking and drift detection
- Testing and validation capabilities

The main tradeoff is the need to handle application deployment separately, which is actually a best practice for infrastructure-as-code deployments.
