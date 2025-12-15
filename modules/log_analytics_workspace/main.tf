

resource "azurerm_log_analytics_workspace" "law" {
  name                = format("IL-log-cind-%s-%s", var.law_name, var.env)
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.law_sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}