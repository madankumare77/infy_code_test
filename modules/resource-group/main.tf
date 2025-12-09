resource "azurerm_resource_group" "this" {
  name     = "${var.rg_name}-rg"
  location = var.location
}