#deployment time take anywhere from 1 to 8 hours for a healthy deployment in the first time.

resource "azurerm_mssql_managed_instance" "this" {
  name                         = var.sqlmi_server_name_prefix
  resource_group_name          = var.rg_name
  location                     = var.location
  subnet_id                    = var.subnet_id
  sku_name                     = "GP_Gen5" // General Purpose, Standard
  vcores                       = 4
  storage_size_in_gb           = 32 #Maximum storage space should be a multiple of 32GB
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
  license_type                 = "LicenseIncluded"
  timezone_id                  = "India Standard Time"
  proxy_override               = "Proxy"
  public_data_endpoint_enabled = false
  minimum_tls_version          = "1.2" #TLS 1.2 is the minimum supported version
  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.sqlmi_server_name_prefix
  })

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  zone_redundant_enabled         = false
  maintenance_configuration_name = null

}

resource "azurerm_mssql_managed_database" "db" {
  for_each                  = toset(var.sqlmi_db_name)
  name                      = each.key
  managed_instance_id       = azurerm_mssql_managed_instance.this.id
  short_term_retention_days = var.short_term_retention_days
}

resource "azurerm_network_security_rule" "allow_management_inbound" {
  name                        = "allow_management_inbound"
  priority                    = 106
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["9000", "9003", "1438", "1440", "1452"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "allow_misubnet_inbound" {
  name                        = "allow_misubnet_inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "allow_health_probe_inbound" {
  name                        = "allow_health_probe_inbound"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "allow_tds_inbound" {
  name                        = "allow_tds_inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny_all_inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "allow_management_outbound" {
  name                        = "allow_management_outbound"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "12000"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "allow_misubnet_outbound" {
  name                        = "allow_misubnet_outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.64/27"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  name                        = "deny_all_outbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = var.network_security_group_name
}

module "sqlmi_diag" {
  count                      = var.enable_sqlmi_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.env, var.sqlmi_server_name_prefix)
  target_resource_id         = azurerm_mssql_managed_instance.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
}

# Reference existing User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uami" {
  name                = format("%s-%s-id", var.env, var.sqlmi_server_name_prefix)
  location            = var.location
  resource_group_name = var.rg_name
}

# # Enable Entra Administrator on SQL MI using UAMI
# resource "azurerm_mssql_managed_instance_active_directory_administrator" "ad_admin" {
#   managed_instance_id = azurerm_mssql_managed_instance.sqlmi.id
#   login_username = "sqladmin"
#   object_id           = azurerm_user_assigned_identity.uami.principal_id
#   tenant_id           = data.azurerm_client_config.current.tenant_id
# }
