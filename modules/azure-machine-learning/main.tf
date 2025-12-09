resource "azurerm_application_insights" "example" {
  name                = "${var.env}-${var.ml_workspace_nameprefix}"
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
}

resource "azurerm_machine_learning_workspace" "example" {
  name                          = "${var.env}-${var.ml_workspace_nameprefix}"
  location                      = var.location
  resource_group_name           = var.rg_name
  application_insights_id       = azurerm_application_insights.example.id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  public_network_access_enabled = false
  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_role_assignment" "aml_storage_access" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.example.identity[0].principal_id
}


# Private Endpoint for AML Workspace
resource "azurerm_private_endpoint" "aml_pe" {
  name                = "${var.env}-aml-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "aml-connection"
    private_connection_resource_id = azurerm_machine_learning_workspace.example.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }
}

# Private DNS Zone for AML Workspace
resource "azurerm_private_dns_zone" "aml_dns" {
  name                = "privatelink.azureml.ms"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aml_dns_link" {
  name                  = "${var.env}-aml-dns-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.aml_dns.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_a_record" "aml_dns_record" {
  name                = azurerm_machine_learning_workspace.example.name
  zone_name           = azurerm_private_dns_zone.aml_dns.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.aml_pe.private_service_connection[0].private_ip_address]
}