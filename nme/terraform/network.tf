# Virtual Network for Private Endpoints
resource "azurerm_virtual_network" "private_endpoints" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = var.private_endpoints_vnet_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [var.private_endpoints_vnet_cidr]
  
  tags = try(var.tags_by_resource["Microsoft.Network/virtualNetworks"], {})
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  count                = var.configure_private_endpoints ? 1 : 0
  name                 = var.private_endpoints_subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_endpoints[0].name
  address_prefixes     = [var.private_endpoints_subnet_cidr]
}

# Subnet for App Service
resource "azurerm_subnet" "app" {
  count                = var.configure_private_endpoints ? 1 : 0
  name                 = var.app_subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.private_endpoints[0].name
  address_prefixes     = [var.app_subnet_cidr]
  
  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "sql" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.sql_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

resource "azurerm_private_dns_zone" "app_service" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.app_service_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.key_vault_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

resource "azurerm_private_dns_zone" "blob" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.blob_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

resource "azurerm_private_dns_zone" "file" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.file_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

resource "azurerm_private_dns_zone" "automation" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = local.automation_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones"], {})
}

# Virtual Network Links for Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.sql[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_service" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.app_service[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.app_service[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.key_vault[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.blob[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.file[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.file[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

resource "azurerm_private_dns_zone_virtual_network_link" "automation" {
  count                 = var.configure_private_endpoints ? 1 : 0
  name                  = "${azurerm_private_dns_zone.automation[0].name}-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.automation[0].name
  virtual_network_id    = azurerm_virtual_network.private_endpoints[0].id
  registration_enabled  = false
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateDnsZones/virtualNetworkLinks"], {})
}

# Private Endpoints
resource "azurerm_private_endpoint" "sql" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = "${azurerm_mssql_server.main.name}-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_mssql_server.main.name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
  
  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}

resource "azurerm_private_endpoint" "app_service" {
  count               = var.configure_private_endpoints && var.private_web_app ? 1 : 0
  name                = "${azurerm_windows_web_app.main.name}-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_windows_web_app.main.name}-psc"
    private_connection_resource_id = azurerm_windows_web_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
  
  private_dns_zone_group {
    name                 = "app-service-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_service[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}

resource "azurerm_private_endpoint" "key_vault" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = "${azurerm_key_vault.main.name}-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_key_vault.main.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
  
  private_dns_zone_group {
    name                 = "key-vault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}

resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = "${azurerm_storage_account.data_protection.name}-blob-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_storage_account.data_protection.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.data_protection.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}

resource "azurerm_private_endpoint" "storage_file" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = "${azurerm_storage_account.data_protection.name}-file-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_storage_account.data_protection.name}-file-psc"
    private_connection_resource_id = azurerm_storage_account.data_protection.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  
  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.file[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}

resource "azurerm_private_endpoint" "automation" {
  count               = var.configure_private_endpoints ? 1 : 0
  name                = "${azurerm_automation_account.main.name}-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  
  private_service_connection {
    name                           = "${azurerm_automation_account.main.name}-psc"
    private_connection_resource_id = azurerm_automation_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Webhook"]
  }
  
  private_dns_zone_group {
    name                 = "automation-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.automation[0].id]
  }
  
  tags = try(var.tags_by_resource["Microsoft.Network/privateEndpoints"], {})
}
