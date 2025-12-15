resource "azurerm_service_plan" "plan" {
  for_each            = var.function_apps
  name                = "asp-${each.key}"
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
  tags                = var.function_apps[each.key].tags
}

# module "storage_account" {
#   source   = "../../modules/storageaccount"
#   for_each = { for k, v in var.function_apps : k => v if v.storage_required }

#   storage_account_name = replace(each.key, "-", "")
#   env                  = "dev"
#   rg_name              = var.rg_name
#   location             = var.location
#   #account_tier         = each.value.account_tier
#   #account_replication_type = each.value.account_replication_type
#   #account_kind         = each.value.account_kind
#   snet_id                  = each.value.subnet_id
#   private_endpoint_enabled = each.value.private_endpoint_enabled
#   #subresource_names    = each.value.subresource_names
#   vnet_id = each.value.vnet_id
#   tags    = var.function_apps[each.key].tags
# }


resource "azurerm_windows_function_app" "windows" {
  for_each                                       = { for k, v in var.function_apps : k => v if v.os_type == "Windows" }
  name                                           = each.key
  location                                       = var.location
  resource_group_name                            = var.rg_name
  service_plan_id                                = azurerm_service_plan.plan[each.key].id
  public_network_access_enabled                  = each.value.public_network_access_enabled
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  storage_account_name                           = each.value.storage_account_name
  site_config {
    application_stack {
      dotnet_version = each.value.runtime_stack
    }
    # Access restrictions to block public
    # ip_restriction {
    #   ip_address = "0.0.0.0/0"
    #   action     = "Deny"
    #   priority   = 100
    #   name       = "BlockAllPublic"
    # }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    WEBSITE_RUN_FROM_PACKAGE = "1"
    #storage_account_name       = each.value.storage_required ? module.storage_account[each.key].storage_account_name : null
    #storage_account_access_key = each.value.storage_required ? module.storage_account[each.key].primary_access_key : null
  }
  virtual_network_subnet_id = each.value.subnet_id
  tags                      = var.function_apps[each.key].tags
}

resource "azurerm_linux_function_app" "linux" {
  for_each                      = { for k, v in var.function_apps : k => v if v.os_type == "Linux" }
  name                          = each.key
  location                      = var.location
  resource_group_name           = var.rg_name
  service_plan_id               = azurerm_service_plan.plan[each.key].id
  public_network_access_enabled = each.value.public_network_access_enabled
  storage_account_name          = each.value.storage_account_name
  #storage_account_access_key                     = each.value.storage_account_access_key
  site_config {
    application_stack {
      java_version = each.value.runtime_stack
    }
    # Access restrictions to block public
    # ip_restriction {
    #   ip_address = "0.0.0.0/0"
    #   action     = "Deny"
    #   priority   = 100
    #   name       = "BlockAllPublic"
    # }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "java"
    WEBSITE_RUN_FROM_PACKAGE = each.value.runtime_stack
  }
  virtual_network_subnet_id = each.value.subnet_id
  identity {
    type         = "UserAssigned"
    identity_ids = [var.UserAssigned_identity]
  }
  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}

data "azurerm_monitor_diagnostic_categories" "func_cats" {
  for_each    = azurerm_linux_function_app.linux
  resource_id = each.value.id
}

# Only enable the 'AppServiceAuditLogs' category (Access Audit)
resource "azurerm_monitor_diagnostic_setting" "func_diag_audit" {
  for_each                   = azurerm_linux_function_app.linux
  name                       = "func-audit-to-law"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = [
      for c in data.azurerm_monitor_diagnostic_categories.func_cats[each.key].log_category_types :
      c if c == "AppServiceAuditLogs"
    ]
    content {
      category = enabled_log.value
    }
  }

  # (Optional) include metrics export if desired:
  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.func_cats[each.key].metrics
    content {
      category = enabled_metric.value
    }
  }
}
variable "log_analytics_workspace_id" {
  type = string
}
variable "UserAssigned_identity" {
  type = string
}
variable "tags" {
  description = "A map of tags to assign to the storage account"
  type        = map(string)
  default     = {}
}




