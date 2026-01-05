resource "azurerm_storage_account" "storage" {
  name                              = lower("${var.storage_account_name}")
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
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  default_to_oauth_authentication   = true

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
      dynamic "container_delete_retention_policy" {
        for_each = var.enable_container_delete_retention ? [1] : []
        content {
          days = var.container_delete_retention_days
        }
      }
    }
  }

  dynamic "immutability_policy" {
    for_each = var.enable_immutability_policy ? [1] : []
    content {
      allow_protected_append_writes = true
      period_since_creation_in_days = var.immutability_period_days
      state                         = var.immutability_policy_state

    }
  }

  lifecycle {
    prevent_destroy = false #var.prevent_storage_account_deletion
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

# resource "azurerm_storage_share" "example" {
#   name               = "sharename"
#   storage_account_id = azurerm_storage_account.storage.id
#   quota              = 50

#   # acl {
#   #   id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"

#   #   access_policy {
#   #     permissions = "rwdl"
#   #     start       = "2019-07-02T09:38:21Z"
#   #     expiry      = "2019-07-02T10:38:21Z"
#   #   }
#   # }
# }


resource "azurerm_monitor_diagnostic_setting" "sa_to_law" {
  count                      = var.enable_storage_diagnostics ? 1 : 0
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
  private_dns_zone_id            = var.private_dns_zone_id
}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
}