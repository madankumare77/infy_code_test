# Key Vault
resource "azurerm_key_vault" "kv" {
  name                          = format("%s-%s", var.name_prefix, var.env)
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  rbac_authorization_enabled    = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : []
  }

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enable_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  lifecycle {
    #prevent_destroy = var.prevent_kv_deletion
    prevent_destroy = false
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}


resource "azurerm_private_endpoint" "pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = format("pvt-endpoint-${azurerm_key_vault.kv.name}")
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = format("pvt-endpoint-${azurerm_key_vault.kv.name}-psc")
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}


module "kv_diag" {
  count = var.enable_diagnostics ? 1 : 0
  #count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.env, azurerm_key_vault.kv.name)
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
  depends_on                 = [var.log_analytics_workspace_id]
}

data "azurerm_client_config" "current" {}


output "kv_id" {
  value = azurerm_key_vault.kv.id
}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
  default     = ""
}