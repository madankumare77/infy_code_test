resource "azurerm_private_endpoint" "this" {
  name                = "${var.name}-${var.subresource_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-${var.subresource_name}-psc"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = [var.subresource_name]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
  }
}

resource "azurerm_private_dns_zone" "example" {
  #count               = var.private_endpoint_enabled ? 1 : 0
  name                = "privatelink.${var.subresource_name}.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  #count                 = var.private_endpoint_enabled ? 1 : 0
  name                  = "${var.name}-${var.subresource_name}-vnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}


