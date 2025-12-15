resource "azurerm_machine_learning_workspace" "example" {
  name                          = var.ml_workspace_nameprefix
  location                      = var.location
  resource_group_name           = var.rg_name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  public_network_access_enabled = false
  identity {
    type = "SystemAssigned"
  }
  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}


# Private Endpoint for AML Workspace
resource "azurerm_private_endpoint" "aml_pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "pvt-endpoint-${azurerm_machine_learning_workspace.example.name}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "aml-connection"
    private_connection_resource_id = azurerm_machine_learning_workspace.example.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "aml-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

variable "private_endpoint_enabled" {
  description = "The name prefix for the Cognitive Account"
  type        = string
}
variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}


data "azurerm_monitor_diagnostic_categories" "aml_cats" {
  resource_id = azurerm_machine_learning_workspace.example.id
}

resource "azurerm_monitor_diagnostic_setting" "aml_diag" {
  name                           = "aml-diag-to-law"
  target_resource_id             = azurerm_machine_learning_workspace.example.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.aml_cats.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.aml_cats.metrics
    content {
      category = enabled_metric.value
    }
  }
}
variable "log_analytics_workspace_id" {
  type = string
}
variable "tags" {
  description = "A map of tags to assign to the storage account"
  type        = map(string)
  default     = {}
}