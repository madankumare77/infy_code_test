

resource "azurerm_application_insights" "preprod" {
  name                = "${var.env}-app-insights"
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
  #retention_in_days   = 30
  workspace_id = var.log_analytics_workspace_id
  tags = {
    Description = "Pre-Prod Application Insights"
    LAW         = "pre-prod-law"
  }
}