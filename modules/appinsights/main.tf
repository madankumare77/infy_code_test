

resource "azurerm_application_insights" "preprod" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
  #retention_in_days   = 30
  workspace_id = var.log_analytics_workspace_id
  tags         = var.tags
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}