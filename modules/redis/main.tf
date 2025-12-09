#############################
#    Redis cache       #
#############################
resource "azurerm_redis_cache" "redis" {
  name                          = format("%s-%s", var.env, var.redis_name_prefix)
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
  name                = "${var.redis_name_prefix}-pe"
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
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink" {
  name                  = "redis-vnet-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
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
