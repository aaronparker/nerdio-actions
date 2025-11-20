# Quick Start Guide

## Prerequisites Checklist

- [ ] Terraform >= 1.0 installed
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Existing Azure Resource Group created
- [ ] Appropriate Azure permissions (Contributor or Owner)

## Deployment Steps

### 1. Clone and Navigate

```bash
cd terraform/template
```

### 2. Create Configuration

Copy the example file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

**Required: Set your resource group name**
```hcl
resource_group_name = "your-existing-rg-name"
```

### 3. Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 4. Plan Deployment

```bash
terraform plan
```

Review the plan output to ensure all resources are correct.

### 5. Deploy

```bash
terraform apply
```

Type `yes` when prompted to confirm.

Deployment typically takes 10-15 minutes.

### 6. Get Outputs

```bash
terraform output
terraform output app_url
```

## Common Configurations

### Minimal Deployment (Development)

```hcl
resource_group_name         = "nmw-dev-rg"
location                    = "eastus"
app_name                    = "nmw-dev"
configure_private_endpoints = false
private_web_app             = false
app_service_plan_sku_name   = "B1"
database_sku_name           = "Basic"
```

### Production with Private Endpoints

```hcl
resource_group_name            = "nmw-prod-rg"
location                       = "eastus"
app_name                       = "nmw-prod"
configure_private_endpoints    = true
private_web_app                = true
private_endpoints_vnet_cidr    = "10.100.0.0/16"
private_endpoints_subnet_cidr  = "10.100.1.0/24"
app_subnet_cidr                = "10.100.2.0/27"
app_service_plan_sku_name      = "P1v3"
database_sku_name              = "S3"
database_tier                  = "Standard"
```

### High Availability Configuration

```hcl
resource_group_name         = "nmw-ha-rg"
location                    = "eastus"
app_name                    = "nmw-ha"
app_service_plan_sku_name   = "P3v3"
database_sku_name           = "P4"
database_tier               = "Premium"
database_max_size           = 536870912000  # 500 GB
```

## Post-Deployment Tasks

### 1. Deploy Application Code

```bash
# Get the web app name
WEB_APP_NAME=$(terraform output -raw web_app_name)

# Deploy using Azure CLI
az webapp deploy \
  --resource-group your-rg-name \
  --name $WEB_APP_NAME \
  --src-path app.zip \
  --type zip
```

### 2. Configure Azure AD Authentication

1. Register app in Azure AD
2. Configure redirect URIs
3. Add application settings to web app

### 3. Run Database Migrations

```bash
# Get connection details
SQL_SERVER=$(terraform output -raw sql_server_fqdn)
DB_NAME=$(terraform output -raw database_name)

# Run migrations (example using sqlcmd)
sqlcmd -S $SQL_SERVER -d $DB_NAME -U your-user -P your-pass -i migrations.sql
```

### 4. Verify Deployment

```bash
# Get the app URL
APP_URL=$(terraform output -raw app_url)

# Test accessibility
curl -I $APP_URL
```

## Common Commands

### View Current State

```bash
terraform show
```

### List Resources

```bash
terraform state list
```

### View Specific Resource

```bash
terraform state show azurerm_windows_web_app.main
```

### Format Code

```bash
terraform fmt
```

### Validate Configuration

```bash
terraform validate
```

### Refresh State

```bash
terraform refresh
```

### Plan Changes

```bash
terraform plan -out=tfplan
```

### Apply Specific Plan

```bash
terraform apply tfplan
```

## Troubleshooting

### Issue: "Resource group does not exist"

**Solution:** Create the resource group first:
```bash
az group create --name your-rg-name --location eastus
```

### Issue: "Key vault name already exists"

**Solution:** Key vault names are globally unique. Either:
1. Use a different app_name
2. Set explicit key_vault_name variable
3. Purge the soft-deleted vault: `az keyvault purge --name vault-name`

### Issue: "SQL Server name not available"

**Solution:** SQL server names are globally unique. Either:
1. Use a different app_name
2. Set explicit sql_server_name variable

### Issue: "Insufficient permissions"

**Solution:** Ensure your account has at least Contributor role:
```bash
az role assignment create \
  --assignee your-email@domain.com \
  --role Contributor \
  --resource-group your-rg-name
```

### Issue: "Private endpoint connectivity"

**Solution:** Check NSG rules and DNS resolution:
```bash
# Test DNS resolution
nslookup sql-server-name.database.windows.net

# Check from VM in VNet
# Should resolve to private IP address (10.x.x.x)
```

## Environment Management

### Using Workspaces

```bash
# Create workspace for different environments
terraform workspace new dev
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev

# List workspaces
terraform workspace list
```

### Using Different Variable Files

```bash
terraform apply -var-file=dev.tfvars
terraform apply -var-file=prod.tfvars
```

### Using Environment-Specific State

Create separate backends for each environment:

```hcl
# backend-dev.hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstate"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
```

```bash
terraform init -backend-config=backend-dev.hcl
```

## Cleanup

### Destroy All Resources

```bash
terraform destroy
```

Type `yes` when prompted.

### Destroy Specific Resources

```bash
terraform destroy -target=azurerm_windows_web_app.main
```

### Preview Destruction

```bash
terraform plan -destroy
```

## Cost Estimation

Approximate monthly costs (US East):

| Configuration | Monthly Cost (USD) |
|---------------|-------------------|
| Development (B1, Basic DB) | ~$50-100 |
| Production (P1v3, S3 DB) | ~$300-500 |
| High Availability (P3v3, P4 DB) | ~$800-1200 |

**Note:** Actual costs depend on:
- Data transfer
- Storage usage
- Log Analytics ingestion
- Automation run time

Use [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for detailed estimates.

## Security Checklist

- [ ] Enable private endpoints for production
- [ ] Configure firewall rules for SQL Server
- [ ] Use managed identities (automatically configured)
- [ ] Enable Key Vault firewall
- [ ] Configure NSG rules for VNet
- [ ] Enable Azure AD authentication
- [ ] Review RBAC assignments
- [ ] Enable audit logging
- [ ] Configure backup policies
- [ ] Implement monitoring and alerts

## Next Steps

1. Review the [README.md](README.md) for detailed documentation
2. Check [CONVERSION_NOTES.md](CONVERSION_NOTES.md) for ARM comparison
3. Customize tags in terraform.tfvars
4. Set up CI/CD pipeline for automated deployments
5. Configure monitoring and alerting
6. Implement disaster recovery plan
7. Document environment-specific configurations

## Getting Help

- **Terraform Issues:** Check [Terraform Documentation](https://www.terraform.io/docs)
- **Azure Provider:** See [azurerm Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **Nerdio Support:** Contact Nerdio support for application-specific issues
- **Azure Support:** Use Azure Portal support for infrastructure issues
