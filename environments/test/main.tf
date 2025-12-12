module "resource_group" {
  source   = "../../modules/resource-group"
  rg_name  = "infy-cicd-test"
  location = var.location
}

module "vnet" {
  source = "../../modules/vnet"

  for_each = {
    for k, v in local.virtual_networks :
    k => v
    if var.enable_virtual_networks
  }

  vnet_name_prefix       = each.key
  env                    = var.env
  location               = each.value.location
  rg_name                = module.resource_group.rg_name
  address_space          = each.value.address_space
  subnet_configs         = each.value.subnet_configs
  enable_ddos_protection = each.value.enable_ddos_protection
  dns_servers            = each.value.dns_servers
}


locals {
  private_dns_zones = {
    kv = {
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
      vnet_id               = module.vnet["vnet003"].vnet_id
    }
    # openai = {
    #   private_dns_zone_name = "privatelink.openai.azure.com"
    #   vnet_id               = module.vnet["vnet003"].vnet_id
    # }
    # storage = {
    #   private_dns_zone_name = "privatelink.blob.core.windows.net"
    #   vnet_id               = module.vnet["vnet003"].vnet_id
    # }
  }
}

module "private_dns_zone" {
  source                = "../../modules/private_dns"
  for_each              = var.enable_private_dns_zone ? local.private_dns_zones : {}
  rg_name               = module.resource_group.rg_name
  vnet_id               = each.value.vnet_id
  private_dns_zone_name = each.value.private_dns_zone_name
  depends_on            = [module.vnet]

}
variable "enable_private_dns_zone" {
  description = "Enable creation of Private DNS Zone"
  type        = bool
  default     = true
}

module "storage_account" {
  source   = "../../modules/storageaccount"
  for_each = var.enable_storage_account ? local.storage_accounts : {}

  storage_account_name              = each.key
  env                               = var.env
  rg_name                           = module.resource_group.rg_name
  location                          = module.resource_group.location
  account_tier                      = each.value.account_tier
  account_replication_type          = each.value.account_replication_type
  account_kind                      = each.value.account_kind
  snet_id                           = each.value.snet_id
  vnet_id                           = each.value.vnet_id
  private_endpoint_enabled          = each.value.private_endpoint_enabled
  subresource_names                 = each.value.subresource_names
  https_traffic_only_enabled        = each.value.https_traffic_only_enabled
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  min_tls_version                   = each.value.min_tls_version
  enable_blob_versioning            = each.value.enable_blob_versioning
  delete_retention_days             = each.value.delete_retention_days
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  log_analytics_workspace_id        = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  enable_storage_diagnostics        = each.value.enable_storage_diagnostics
  log_categories                    = each.value.log_categories
  metric_categories                 = each.value.metric_categories
  tags                              = each.value.tags
}


module "function_app" {
  source        = "../../modules/function_app"
  function_apps = var.enable_function_app ? local.function_apps : {}
  rg_name       = module.resource_group.rg_name
  location      = module.resource_group.location
  env           = var.env
}

module "kv" {
  for_each = var.enable_kv ? local.kv_configs : {}

  source                        = "../../modules/kv"
  name_prefix                   = each.key
  rg_name                       = module.resource_group.rg_name
  location                      = module.resource_group.location
  env                           = var.env
  sku_name                      = each.value.sku_name
  purge_protection_enabled      = each.value.purge_protection_enabled
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  enable_rbac_authorization     = each.value.enable_rbac_authorization
  subnet_id                     = each.value.subnet_id
  vnet_id                       = each.value.vnet_id
  log_analytics_workspace_id    = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  public_network_access_enabled = each.value.public_network_access_enabled
  log_categories                = each.value.log_categories
  metric_categories             = each.value.metric_categories
  private_endpoint_enabled      = each.value.private_endpoint_enabled # Set to true if you want to enable private endpoint
  tags                          = each.value.tags
  depends_on                    = [module.law.log_analytics_workspace_id] # Ensure the log analytics workspace is created before KV
  private_dns_zone_id           = module.private_dns_zone["kv"].private_dns_zone_id
}

module "aks" {
  for_each = var.enable_aks ? local.aks_configs : {}

  source = "../../modules/aks"

  aks_name_prefix            = each.key
  rg_name                    = module.resource_group.rg_name
  location                   = module.resource_group.location
  env                        = var.env
  kubernetes_version         = each.value.kubernetes_version
  private_cluster            = each.value.private_cluster
  network_plugin             = each.value.network_plugin
  load_balancer_sku          = each.value.load_balancer_sku
  os_sku                     = each.value.os_sku
  node_os_disk_type          = each.value.node_os_disk_type
  enable_host_encryption     = each.value.encryption_host
  vnet_subnet_id             = each.value.vnet_subnet_id
  default_node_pool          = each.value.default_node_pool
  additional_node_pools      = each.value.additional_node_pools
  aks_dns_service_ip         = each.value.aks_dns_service_ip
  aks_service_cidr           = each.value.aks_service_cidr
  log_analytics_workspace_id = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  tags                       = each.value.tags
}

module "postgresql_flex" {
  source                        = "../../modules/postgresql_flex"
  for_each                      = var.enable_postgresql_flex ? local.postgresql_servers : {}
  psql_server_name_prefix       = each.key
  env                           = var.env
  location                      = module.resource_group.location
  rg_name                       = module.resource_group.rg_name
  subnet_id                     = each.value.subnet_id
  vnet_id                       = each.value.vnet_id
  psql_administrator_login      = each.value.psql_administrator_login
  psql_administrator_password   = each.value.psql_administrator_password
  psql_version                  = each.value.psql_version
  sku_name                      = each.value.sku_name
  storage_mb                    = each.value.storage_mb
  zone                          = each.value.zone
  high_availability_mode        = each.value.high_availability_mode
  standby_zone                  = each.value.standby_zone
  active_directory_auth_enabled = each.value.active_directory_auth_enabled
  log_analytics_workspace_id    = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  log_categories                = each.value.log_categories
  metric_categories             = each.value.metric_categories
  tags                          = each.value.tags
  db_name                       = each.value.db_name
}

module "apim" {
  for_each                   = var.enable_apim ? local.apim_configs : {}
  source                     = "../../modules/apim"
  apim_name_prefix           = each.key
  environment                = var.env
  rg_name                    = module.resource_group.rg_name
  location                   = module.resource_group.location
  subnet_id                  = each.value.subnet_id
  publisher_name             = each.value.publisher_name
  publisher_email            = each.value.publisher_email
  sku_name                   = each.value.sku_name
  log_analytics_workspace_id = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  tags                       = each.value.tags
}

# # main.tf (root module)
# module "api_management_apis" {
#   source              = "../../modules/apis"
#   apis                = local.transformed_apis
#   resource_group_name = module.resource_group.rg_name
#   api_management_name = module.apim["apim3"].apim_name_prefix
# }

module "redis" {
  for_each = var.enable_redis_cache ? local.redis_cache : {}

  source                     = "../../modules/redis"
  redis_name_prefix          = each.key
  location                   = module.resource_group.location
  rg_name                    = module.resource_group.rg_name
  env                        = var.env
  subnet_id                  = each.value.subnet_id
  redis_capacity             = each.value.redis_capacity
  redis_family               = each.value.redis_family
  redis_sku_name             = each.value.redis_sku_name
  redis_minimum_tls_version  = each.value.redis_minimum_tls_version
  redis_version              = each.value.redis_version
  vnet_id                    = each.value.vnet_id
  enable_redis_diagnostics   = each.value.enable_redis_diagnostics
  log_analytics_workspace_id = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  #log_categories             = each.value.log_categories
  metric_categories = each.value.metric_categories
  tags              = each.value.tags
}

module "sqlmi" {
  source                       = "../../modules/sqlmi"
  for_each                     = var.enable_sqlmi ? local.sqlmi_servers : {}
  env                          = var.env
  sqlmi_server_name_prefix     = each.key
  rg_name                      = module.resource_group.rg_name
  location                     = module.resource_group.location
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  subnet_id                    = each.value.subnet_id
  sqlmi_db_name                = each.value.sqlmi_db_name
  enable_sqlmi_diagnostics     = each.value.enable_sqlmi_diagnostics
  log_analytics_workspace_id   = var.enable_log_analytics_workspace ? module.law.log_analytics_workspace_id : ""
  metric_categories            = each.value.metric_categories
  network_security_group_name  = each.value.network_security_group_name
  tags                         = each.value.tags
}

module "law" {
  source            = "../../modules/log_analytics_workspace"
  count             = var.enable_log_analytics_workspace ? 1 : 0
  rg_name           = module.resource_group.rg_name
  location          = module.resource_group.location
  env               = var.env
  law_name          = "infy"
  law_sku           = "PerGB2018" # Use the appropriate SKU for your use
  retention_in_days = 30
  tags = {
    environment = var.env
    created_by  = "terraform"
  }
}


module "documentIntellegence" {
  source                = "../../modules/documentIntelligence"
  for_each              = var.enable_di_account ? local.di_account : {}
  di_name_prefix        = each.value.di_name_prefix
  env                   = var.env
  location              = var.location
  rg_name               = module.resource_group.rg_name
  sku_name              = each.value.sku_name
  kind                  = each.value.kind
  vnet_id               = each.value.vnet_id
  subnet_id             = each.value.subnet_id
  custom_subdomain_name = "${var.env}-infy-di"
}

locals {
  azure_openai = {
    aoai001 = {
      location              = "East US" #Central India not supported for openAI
      sku_name              = "S0"
      kind                  = "OpenAI"
      private_dns_zone_name = "privatelink.openai.azure.com"
      subnet_id             = var.enable_azure_openai ? module.vnet["vnet004"].subnet_ids["snet-aoai"] : ""
      vnet_id               = var.enable_azure_openai ? module.vnet["vnet004"].vnet_id : ""
    }
  }
}

module "azure_openai" {
  source                = "../../modules/azure_openai"
  for_each              = var.enable_azure_openai ? local.azure_openai : {}
  env                   = var.env
  name_prefix           = each.key
  location              = each.value.location
  rg_name               = module.resource_group.rg_name
  sku_name              = each.value.sku_name
  kind                  = each.value.kind
  custom_subdomain      = "${var.env}-${each.key}"
  private_dns_zone_name = each.value.private_dns_zone_name
  subnet_id             = each.value.subnet_id
  vnet_id               = each.value.vnet_id
}

module "azure_machine_learning" {
  source                  = "../../modules/azure-machine-learning"
  for_each                = var.enable_aml_workspace ? local.aml_workspace : {}
  env                     = var.env
  location                = var.location
  rg_name                 = module.resource_group.rg_name
  ml_workspace_nameprefix = each.value.ml_workspace_nameprefix
  vnet_id                 = each.value
  subnet_id               = each.value.subnet_id
  key_vault_id            = each.value.key_vault_id
  storage_account_id      = each.value.storage_account_id
}

module "azure_documentdb" {
  source                 = "../../modules/azure_documentdb"
  for_each               = var.enable_azure_documentdb ? local.azure_documentdb : {}
  env                    = var.env
  cluster_name_prefix    = each.key
  location               = var.location
  rg_name                = module.resource_group.rg_name
  administrator_username = each.value.administrator_username
  administrator_password = each.value.administrator_password
  shard_count            = each.value.shard_count
  compute_tier           = each.value.compute_tier
  high_availability_mode = each.value.high_availability_mode
  storage_size_in_gb     = each.value.storage_size_in_gb
  mongodb_version        = each.value.mongodb_version
  geo_replica_location   = each.value.geo_replica_location
  kv_id                  = module.kv["kv003"].kv_id
  vnet_id                = module.vnet["vnet003"].vnet_id
  subnet_id              = module.vnet["vnet003"].subnet_ids["snet-cosmos-mongo"]
}

module "azure_identity" {
  source        = "../../modules/azure_identity"
  for_each      = var.enable_UserAssignedIdenti ? local.UserAssignedIdenti : {}
  identity_name = each.value.identity_name
  env           = var.env
  location      = var.location
  rg_name       = module.resource_group.rg_name
}

# module "cosmosdb" {
#   source = "../../modules/cosmosdb"
#   env      = var.env
#   cosmosdb_name_prefix = "cosmosdb"
#   location = var.location
#   rg_name  = module.resource_group.rg_name
# }

# module "AppInsights" {
#   source                     = "../../modules/appinsights"
#   env                        = var.env
#   location                   = var.location
#   rg_name                    = module.resource_group.rg_name
#   log_analytics_workspace_id = module.law.log_analytics_workspace_id
# }


# module "vnet_peering" {
#   source = "../../modules/vnet_peering"

#   enable_peering = false

#   hub_vnets = {
#     hub1 = {
#       name            = module.vnet["vnet003"].vnet_name #Vnet name
#       resource_group  = module.resource_group.rg_name #vnet rg name
#       vnet_id         = module.vnet["vnet003"].vnet_id #"vnet ID. /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"
#       subscription_id = "" #<sub-id>
#     }
#   }

#   spoke_vnets = {
#     spoke1 = {
#       name            = module.vnet["vnet004"].vnet_name #Vnet name
#       resource_group  = module.resource_group.rg_name #vnet rg name
#       vnet_id         = module.vnet["vnet004"].vnet_id #"vnet ID. /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"
#       subscription_id = "" #<sub-id>
#     }
#   }
# }