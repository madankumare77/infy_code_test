
# ----------------------------
# Azure AI Document Intelligence
# ----------------------------
# Implemented as a Cognitive Services account with kind = "FormRecognizer"
resource "azurerm_cognitive_account" "di" {
  name                = lower("${var.di_name_prefix}")
  location            = var.location
  resource_group_name = var.rg_name

  kind                  = var.kind     # Document Intelligence
  sku_name              = var.sku_name # e.g., S0
  custom_subdomain_name = var.custom_subdomain_name

  # Lock down public access; only Private Endpoint traffic will succeed
  public_network_access_enabled = false

  #identity { type = "SystemAssigned" }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}

# ----------------------------
# Private Endpoint to the DI account
# ----------------------------
resource "azurerm_private_endpoint" "di_pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "pvt-endpoint-${azurerm_cognitive_account.di.name}"
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

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}


data "azurerm_monitor_diagnostic_categories" "cats" {
  count = var.enable_diagnostics ? 1 : 0
  resource_id = azurerm_cognitive_account.di.id
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  count = var.enable_diagnostics ? 1 : 0
  name                       = "cognitive-diag-to-law"
  target_resource_id         = azurerm_cognitive_account.di.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.cats[0].log_category_types
    content {
      category = enabled_log.value
    }
  }

  # Enable all metric categories if present
  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.cats[0].metrics
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

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}
variable "private_endpoint_enabled" {
  description = "The name prefix for the Cognitive Account"
  type        = string
}
variable "enable_diagnostics" {
  description = "Enable diagnostic settings for the Key Vault"
  type        = bool
  default     = false
}

########################################################
# outputs.tf
########################################################
output "di_endpoint" {
  description = "Document Intelligence endpoint (public hostname that resolves to the PE inside your VNet)."
  value       = azurerm_cognitive_account.di.endpoint
}

output "di_id" {
  value       = azurerm_cognitive_account.di.id
}