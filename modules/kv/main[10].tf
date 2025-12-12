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

  # enabled_for_deployment          = var.enabled_for_deployment
  # enabled_for_disk_encryption     = var.enable_for_disk_encryption
  # enabled_for_template_deployment = var.enabled_for_template_deployment

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.name_prefix
      "INFY_EA_CustomTag01": "No Po"
      "INFY_EA_CustomTag02": "Infosys Limited"
      "INFY_EA_CustomTag03": "EPMCFG"
      "INFY_EA_CustomTag04": "PaaS"
      "INFY_EA_BusinessUnit": "IS"
      "INFY_EA_Automation": "No"
      "INFY_EA_CostCenter": "No FR_IS"
      "INFY_EA_Technical_Tag": "EPM_CFG@infosys.com"
      "INFY_EA_Role": "key vault"
      "INFY_EA_ProjectCode": "EPMPRJBE"
      "INFY_EA_Purpose": "IS Internal"
      "INFY_EA_Weekendshutdown": "No"
      "INFY_EA_Workinghours": "00:00 23:59",
      "INFY_EA_WorkLoadType": "Test"
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
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.use_existing_private_dns_zone ? [data.azurerm_private_dns_zone.existing[0].id] : [azurerm_private_dns_zone.example[0].id]
  }
}

resource "azurerm_private_dns_zone" "example" {
  count               = var.private_endpoint_enabled && !var.use_existing_private_dns_zone ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  count                 = var.private_endpoint_enabled && var.create_private_dns_link ? 1 : 0
  name                  = format("%s-%s-link", var.env, azurerm_key_vault.kv.name)
  private_dns_zone_name = var.use_existing_private_dns_zone ? data.azurerm_private_dns_zone.existing[0].name : azurerm_private_dns_zone.example[0].name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.rg_name
}


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

// Optionally use an existing private DNS zone instead of creating one
data "azurerm_private_dns_zone" "existing" {
  count               = var.private_endpoint_enabled && var.use_existing_private_dns_zone ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}


output "kv_id" {
  value = azurerm_key_vault.kv.id
}

variable "use_existing_private_dns_zone" {
  description = "If true, use an existing privatelink.vaultcore.azure.net DNS zone in the RG instead of creating a new one."
  type        = bool
  default     = false
}

variable "create_private_dns_link" {
  description = "If true, create a VNet link to the private DNS zone. Set to false when the VNet is already linked to avoid conflicts."
  type        = bool
  default     = true
}