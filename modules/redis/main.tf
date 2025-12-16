#############################
#    Redis cache       #
#############################
resource "azurerm_redis_cache" "redis" {
  name                          = var.redis_name_prefix
  location                      = var.location
  resource_group_name           = var.rg_name
  capacity                      = var.redis_capacity            # P2 => capacity 2
  family                        = var.redis_family              #"C"
  sku_name                      = var.redis_sku_name            #"Standard"
  non_ssl_port_enabled          = false                         # only port 6380 will be open and port 6379 (non-TLS) will be disabled
  minimum_tls_version           = var.redis_minimum_tls_version #"1.2"
  redis_version                 = var.redis_version
  public_network_access_enabled = false

  # identity {
  #   type = "SystemAssigned" # or "UserAssigned" with identity_ids
  # }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.redis_name_prefix
  })

}

resource "azurerm_private_endpoint" "redis_pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "pvt-endpoint-${var.redis_name_prefix}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.redis_name_prefix}-pe-psc"
    private_connection_resource_id = azurerm_redis_cache.redis.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}


module "redis_diag" {
  count                      = var.enable_redis_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic", var.env, var.redis_name_prefix)
  target_resource_id         = azurerm_redis_cache.redis.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}
variable "private_endpoint_enabled" {
  description = "The name prefix for the Cognitive Account"
  type        = string
}

output "redis_id" {
  value = azurerm_redis_cache.redis.id
}