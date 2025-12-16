resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.psql_server_name_prefix
  resource_group_name    = var.rg_name
  location               = var.location #Multi-Zone HA is not supported in Centarl India region so we default to SameZone
  sku_name               = var.sku_name #az postgres flexible-server list-skus --location centralindia
  storage_mb             = var.storage_mb
  version                = var.psql_version
  administrator_login    = var.psql_administrator_login
  administrator_password = var.psql_administrator_password #random_password.pass.result
  zone                   = var.zone

  high_availability {
    mode                      = var.high_availability_mode
    standby_availability_zone = var.standby_zone
  }

  authentication {
    #password_auth_enabled         = var.password_auth_enabled
    active_directory_auth_enabled = var.active_directory_auth_enabled
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }


  backup_retention_days         = var.backup_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_id #required when setting a delegated_subnet_id

  depends_on = [var.subnet_id]

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.psql_server_name_prefix
    }
  )
}


resource "azurerm_postgresql_flexible_server_database" "db" {
  for_each  = toset(var.db_name)
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = var.charset
  collation = var.collation
}

module "postgres_diag" {
  count = var.enable_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.env, var.psql_server_name_prefix)
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories    #["PostgreSQLLogs"]
  metric_categories          = var.metric_categories #["AllMetrics"]
}

data "azurerm_client_config" "current" {}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}
variable "enable_diagnostics" {
  description = "Enable diagnostic settings for the Key Vault"
  type        = bool
  default     = false
}

