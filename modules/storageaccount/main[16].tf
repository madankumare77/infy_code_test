resource "azurerm_storage_account" "storage" {
  name                              = lower("${var.storage_account_name}${var.env}")
  resource_group_name               = var.rg_name
  location                          = var.location
  account_tier                      = var.account_tier             #"Standard"
  account_replication_type          = var.account_replication_type #"LRS"
  account_kind                      = var.account_kind             #"StorageV2"
  access_tier                       = var.access_tier
  public_network_access_enabled     = var.public_network_access_enabled
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  min_tls_version                   = var.min_tls_version #"TLS1_1.2"
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  dynamic "network_rules" {
    for_each = var.snet_id != "" ? [1] : []
    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = [var.snet_id]
      #bypass                     = ["AzureServices"]
    }

  }


  # blob_properties {
  #   versioning_enabled = var.enable_blob_versioning
  #   delete_retention_policy {
  #     days = var.delete_retention_days # Example: Keep deleted blobs for 7 days
  #   }
  # }

  dynamic "blob_properties" {
    for_each = var.account_kind == "StorageV2" ? [1] : []
    content {
      versioning_enabled = var.enable_blob_versioning
      delete_retention_policy {
        days = var.delete_retention_days
      }
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.storage_account_name
      #"INFY_EA_ResourceName" = "${azurerm_storage_account.storage.name}",
    }
  )
}


#resource "azurerm_storage_share" "quota" {
#  name                 = "fileshare"
#  storage_account_name = azurerm_storage_account.storage.name
#  quota                = 1024 # 1 TB
#}


# module "storage_diag" {
#   count                      = var.enable_storage_diagnostics ? 1 : 0
#   source                     = "../../modules/diagnostic_setting"
#   name                       = format("%s-%s-diagnostic", var.env, azurerm_storage_account.storage.name)
#   target_resource_id         = "${azurerm_storage_account.storage.id}/blobServices/default"
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#   log_categories             = var.log_categories    #["StorageRead", "StorageWrite", "StorageDelete"]
#   metric_categories          = var.metric_categories #["AllMetrics"]
# }


resource "azurerm_monitor_diagnostic_setting" "sa_to_law" {
  name                       = format("%s-%s-diagnostic", var.env, azurerm_storage_account.storage.name)
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Capture platform metrics
  # metric {
  #   category = "AllMetrics"
  #   enabled  = true
  #   retention_policy {
  #     enabled = false
  #     days    = 0
  #   }
  # }
  metric {
    category = "Capacity"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  metric {
    category = "Transaction"
    enabled  = true
    retention_policy {
    days    = 0
    enabled = false
    }
  }
}


module "private_endpoints" {
  source = "../../modules/pe"

  for_each = var.private_endpoint_enabled ? toset(var.subresource_names) : toset([])

  name                           = azurerm_storage_account.storage.name
  location                       = var.location
  resource_group_name            = var.rg_name
  private_connection_resource_id = azurerm_storage_account.storage.id
  subresource_name               = each.value
  vnet_id                        = var.vnet_id
  subnet_id                      = var.snet_id
}



resource "random_id" "unique" {
  byte_length = 4
}