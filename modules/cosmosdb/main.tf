# Cosmos DB Account for MongoDB 
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = var.cosmosdb_name_prefix
  location            = var.location
  resource_group_name = var.rg_name
  offer_type          = var.offer_type
  kind                = var.cosmos_kind # MongoDB API
  #enable_free_tier    = false                   # Created no (not free tier)
  #enable_multiple_write_locations = true        # High Availability enabled
  public_network_access_enabled = false # public-network-access FALSE

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  geo_location {
    location          = var.geo_location1 # Read Replica Region
    failover_priority = 1
  }

  backup {
    type = "Continuous"
    tier = "Continuous30Days"
  }

  analytical_storage_enabled = false

  dynamic "identity" {
    for_each = var.UserAssigned_identity != "" ? [var.UserAssigned_identity] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.UserAssigned_identity]
    }
  }

  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [var.UserAssigned_identity]
  # }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}

# MongoDB Database
#resource "azurerm_cosmosdb_mongo_database" "mongo_db" {
#  name                = var.cosmosdb_name
#  resource_group_name = var.rg_name
#  account_name        = azurerm_cosmosdb_account.cosmosdb.name
#  throughput          = 4000 # Approx for M40 tier
#}

# # MongoDB Collection (Shard)
# resource "azurerm_cosmosdb_mongo_collection" "mongo_collection" {
#   name                = "${var.env}-collection"
#   resource_group_name = var.rg_name
#   account_name        = azurerm_cosmosdb_account.cosmosdb.name
#   database_name       = azurerm_cosmosdb_mongo_database.mongo_db.name
#   shard_key           = "uniqueKey" # Shard key
#   throughput          = 4000
#   index {
#     keys   = ["_id"]
#     unique = true
#   }

# }





resource "azurerm_private_endpoint" "cosmos_pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "pvt-endpoint-${azurerm_cosmosdb_account.cosmosdb.name}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "pvt-endpoint-${azurerm_cosmosdb_account.cosmosdb.name}"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos_diag" {
  count = var.enable_diagnostics ? 1 : 0
  name                       = "cosmos-diag"
  target_resource_id         = azurerm_cosmosdb_account.cosmosdb.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_log {
    category = "QueryRuntimeStatistics"
  }
  enabled_log {
    category = "PartitionKeyStatistics"
  }
  enabled_log {
    category = "MongoRequests"
  }

  # enabled_metric {
  #   category = "AllMetrics"
  # }
  enabled_metric {
    category = "Requests"
  }
  enabled_metric {
    category = "SLI"
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


# Outputs
output "cosmosdb_id" {
  value =  azurerm_cosmosdb_account.cosmosdb.id
}
output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb.endpoint
}

output "cosmosdb_primary_key" {
  value = azurerm_cosmosdb_account.cosmosdb.primary_key
}