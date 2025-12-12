
resource "azurerm_mongo_cluster" "example" {
  name                   = "${var.cluster_name_prefix}"
  location               = var.location
  resource_group_name    = var.rg_name
  administrator_username = var.administrator_username
  administrator_password = var.administrator_password #random_password.mongo_admin_pwd.result
  shard_count            = var.shard_count
  compute_tier           = var.compute_tier           #"Free"
  high_availability_mode = var.high_availability_mode #"Disabled"
  storage_size_in_gb     = var.storage_size_in_gb     #"32"
  version                = var.mongodb_version        #"8.0"
}

resource "azurerm_mongo_cluster" "example_geo_replica" {
  count               = var.high_availability_mode == "ZoneRedundantPreferred" ? 1 : 0
  name                = "${azurerm_mongo_cluster.example.name}-geo"
  location            = var.geo_replica_location
  resource_group_name = var.rg_name
  source_server_id    = azurerm_mongo_cluster.example.id
  source_location     = azurerm_mongo_cluster.example.location
  create_mode         = "GeoReplica"

  lifecycle {
    ignore_changes = ["administrator_username", "high_availability_mode", "preview_features", "shard_count", "storage_size_in_gb", "compute_tier", "version"]
  }
}

# resource "random_password" "mongo_admin_pwd" {
#   length           = 12
#   special          = true
#   min_upper        = 2
#   min_lower        = 2
#   min_numeric      = 2
#   min_special      = 2
# }


# resource "azurerm_key_vault_secret" "mongo_admin_pwd" {
#   name         = "mongo-admin-password"
#   value        = random_password.mongo_admin_pwd.result
#   key_vault_id = var.kv_id
#   content_type = "password"
# }


# Cosmos Mongo vCore Private DNS
resource "azurerm_private_dns_zone" "cosmos_zone" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_zone_link" {
  name                  = "cosmos-zone-link"
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_zone.name
  resource_group_name   = var.rg_name
  virtual_network_id    = var.vnet_id
}

# Cosmos Mongo vCore Private Endpoint
resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "${azurerm_mongo_cluster.example.name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_mongo_cluster.example.name}-psc"
    private_connection_resource_id = azurerm_mongo_cluster.example.id
    subresource_names              = ["MongoCluster"] # groupId for vCore Mongo
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_zone.id]
  }
}


