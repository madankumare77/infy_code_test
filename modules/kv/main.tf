# Key Vault
resource "azurerm_key_vault" "kv" {
  name                          = format("%s-%s-%s", var.env, var.name_prefix, "${random_id.unique.hex}")
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  enable_rbac_authorization     = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : []
  }

  # Access settings for deployment integration
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enanble_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.name_prefix
    }
  )
}

resource "azurerm_private_endpoint" "pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = format("%s-%s-pe", var.env, var.name_prefix)
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = format("%s-%s-psc", var.env, var.name_prefix)
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# resource "azurerm_private_dns_zone" "example" {
#   count               = var.private_endpoint_enabled ? 1 : 0
#   name                = "privatelink.vaultcore.azure.net"
#   resource_group_name = var.rg_name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   count                 = var.private_endpoint_enabled ? 1 : 0
#   name                  = format("%s-%s-link", var.env, azurerm_key_vault.kv.name)
#   private_dns_zone_name = azurerm_private_dns_zone.example[0].name
#   virtual_network_id    = var.vnet_id
#   resource_group_name   = var.rg_name
# }


# resource "azurerm_private_dns_a_record" "dns_a_sta" {
#   count               = var.private_endpoint_enabled ? 1 : 0
#   name                = format("%s-%s-a_record", var.env, azurerm_key_vault.kv.name)
#   zone_name           = azurerm_private_dns_zone.example[0].name
#   resource_group_name = var.rg_name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.pe[0].private_service_connection[0].private_ip_address]
#   #records             = [azurerm_private_endpoint.pe.private_service_connection.0.private_ip_address]
# }


module "kv_diag" {
  count                      = var.enable_kv_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.env, azurerm_key_vault.kv.name)
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
}


data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}

resource "random_id" "unique" {
  byte_length = 4
}


output "kv_id" {
  value = azurerm_key_vault.kv.id
}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}