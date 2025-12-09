
# ----------------------------
# Azure AI Document Intelligence
# ----------------------------
# Implemented as a Cognitive Services account with kind = "FormRecognizer"
resource "azurerm_cognitive_account" "di" {
  name                = lower("${var.env}-${var.di_name_prefix}")
  location            = var.location
  resource_group_name = var.rg_name

  kind                  = "FormRecognizer" # Document Intelligence
  sku_name              = var.sku_name     # e.g., S0
  custom_subdomain_name = var.custom_subdomain_name

  # Lock down public access; only Private Endpoint traffic will succeed
  public_network_access_enabled = false

  identity { type = "SystemAssigned" }

  tags = {
    environment = var.env
    workload    = "document-intelligence"
  }
}

# ----------------------------
# Private DNS zone for Cognitive Services
# ----------------------------
# The DI endpoint uses the cognitiveservices domain; create & link the zone
resource "azurerm_private_dns_zone" "cog_zone" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cog_zone_link" {
  name                  = "di-zone-link"
  private_dns_zone_name = azurerm_private_dns_zone.cog_zone.name
  resource_group_name   = var.rg_name
  virtual_network_id    = var.vnet_id
}

# ----------------------------
# Private Endpoint to the DI account
# ----------------------------
resource "azurerm_private_endpoint" "di_pe" {
  name                = "${azurerm_cognitive_account.di.name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_cognitive_account.di.name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.di.id
    # Cognitive Services Private Link subresource for inbound traffic:
    # groupId/subresource "account"
    subresource_names    = ["account"] # <- required
    is_manual_connection = false
  }

  private_dns_zone_group {
    name                 = "di-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cog_zone.id]
  }
}

########################################################
# outputs.tf
########################################################
output "di_endpoint" {
  description = "Document Intelligence endpoint (public hostname that resolves to the PE inside your VNet)."
  value       = azurerm_cognitive_account.di.endpoint
}

output "di_private_endpoint_ip" {
  description = "Private IP(s) of the DI Private Endpoint NIC."
  value       = azurerm_private_endpoint.di_pe.private_service_connection[0].private_ip_address
}

