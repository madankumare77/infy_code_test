
# Create an Azure API Management service instance
resource "azurerm_api_management" "example" {
  name                = "${var.environment}-${var.apim_name_prefix}-apim"
  location            = var.location
  resource_group_name = var.rg_name
  publisher_name      = var.publisher_name  #"My Company"
  publisher_email     = var.publisher_email #"madankumare77@gmail.com"
  sku_name            = var.sku_name        # Or any other SKU you require

  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = var.subnet_id
  }

  # identity {
  #   type = "SystemAssigned"
  # }

  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     azurerm_user_assigned_identity.msi.id
  #   ]
  # }
}



resource "azurerm_network_security_group" "apim_nsg" {
  name                = "nsg-apim"
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet_network_security_group_association" "apim_subnet_assoc" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}


# Allow inbound HTTPS traffic for Gateway (runtime)
resource "azurerm_network_security_rule" "inbound_gateway" {
  name                        = "Allow-HTTPS-Gateway"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  resource_group_name         = var.rg_name
}

# Allow inbound Management traffic
resource "azurerm_network_security_rule" "inbound_management" {
  name                        = "Allow-Management-3443"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  resource_group_name         = var.rg_name
}

# Allow outbound HTTPS
resource "azurerm_network_security_rule" "outbound_https" {
  name                        = "Allow-Outbound-HTTPS"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  resource_group_name         = var.rg_name
}

# Allow outbound DNS
resource "azurerm_network_security_rule" "outbound_dns" {
  name                        = "Allow-Outbound-DNS"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
  resource_group_name         = var.rg_name
}


module "apim_diag" {
  count                      = var.enable_apim_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.environment, var.apim_name_prefix)
  target_resource_id         = azurerm_api_management.example.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
}


resource "azurerm_application_insights" "example" {
  name                = "appi-example"
  location            = azurerm_api_management.example.location
  resource_group_name = azurerm_api_management.example.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
}
