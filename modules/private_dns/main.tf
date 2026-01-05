resource "azurerm_private_dns_zone" "example" {
  count = var.create_private_dns_zone ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = var.rg_name
}

data "azurerm_private_dns_zone" "example" {
  count = var.create_private_dns_zone ? 0 : 1
  name                = var.private_dns_zone_name
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = format("%s-link", var.private_dns_zone_name)
  private_dns_zone_name = var.private_dns_zone_name
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

variable "create_private_dns_zone" {
  description = "Flag to determine whether to create a new Private DNS Zone or use an existing one."
  type        = bool
  default     = true
}

output "private_dns_zone_id" {
  value = var.create_private_dns_zone ? azurerm_private_dns_zone.example[0].id : data.azurerm_private_dns_zone.example[0].id
}