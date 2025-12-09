

resource "azurerm_log_analytics_workspace" "law" {
  name                = format("%s-%s-law", var.env, var.law_name)
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.law_sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}
