resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = format("%s-link", var.private_dns_zone_name)
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.rg_name
}

variable "rg_name" {
  description = "The name of the resource group in which to create the Private DNS Zone."
  type        = string
}
variable "vnet_id" {
  description = "The ID of the Virtual Network to link to the Private DNS Zone."
  type        = string
}
variable "private_dns_zone_name" {
  description = "The name of the Private DNS Zone to create."
  type        = string
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.example.id
}