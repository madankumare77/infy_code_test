# Reference existing resource group for the test environment
data "azurerm_resource_group" "rg" {
  name = "madan-test"
}

# Management lock at RG scope
resource "azurerm_management_lock" "rg_lock" {
  count      = var.rg_lock_enable ? 1 : 0
  name       = "rg-${var.lock_level}"
  scope      = data.azurerm_resource_group.rg.id
  lock_level = var.lock_level #"CanNotDelete" # or "ReadOnly"
  notes      = "Protect RG and all child resources from accidental deletion"
}


# Deploy virtual networks with subnets and network security configurations
module "vnet" {
  source = "../../modules/vnet"

  for_each = {
    for k, v in local.virtual_networks :
    k => v
    if var.enable_virtual_networks
  }

  vnet_name_prefix       = each.key
  env                    = var.env
  location               = data.azurerm_resource_group.rg.location
  rg_name                = data.azurerm_resource_group.rg.name
  address_space          = each.value.address_space
  subnet_configs         = each.value.subnet_configs
  enable_ddos_protection = each.value.enable_ddos_protection
  dns_servers            = each.value.dns_servers
  tags                   = each.value.tags
}

module "nsg" {
  source         = "../../modules/nsg"
  for_each       = { for k, v in local.nsg_configs : k => v if var.enable_nsg }
  nsg_name       = each.value.nsg_name
  create_nsg     = each.value.create_nsg
  location       = each.value.location
  rg_name        = each.value.rg_name
  security_rules = lookup(each.value, "security_rules", [])
}

module "nsg_association" {
  source     = "../../modules/nsg_association"
  for_each   = var.enable_nsg_association ? local.nsg_association_configs : {}
  subnet_id  = each.value.subnet_id
  nsg_id     = each.value.nsg_id
  depends_on = [module.vnet, module.nsg]
}


module "private_dns_zone" {
  source                = "../../modules/private_dns"
  for_each              = var.enable_private_dns_zone ? local.private_dns_zones : {}
  rg_name               = each.value.rg_name
  create_private_dns_zone = each.value.create_private_dns_zone
  vnet_id               = each.value.vnet_id
  private_dns_zone_name = each.value.private_dns_zone_name
  depends_on            = [module.vnet]

}

# Deploy storage accounts with private endpoints and diagnostic settings
module "storage_account" {
  source   = "../../modules/storageaccount"
  for_each = var.enable_storage_account ? local.storage_accounts : {}

  storage_account_name              = each.key
  env                               = var.env
  rg_name                           = data.azurerm_resource_group.rg.name
  location                          = data.azurerm_resource_group.rg.location
  account_tier                      = each.value.account_tier
  account_replication_type          = each.value.account_replication_type
  account_kind                      = each.value.account_kind
  access_tier                       = each.value.access_tier
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
  log_analytics_workspace_id        = each.value.log_analytics_workspace_id
  enable_storage_diagnostics        = each.value.enable_storage_diagnostics
  enable_immutability_policy        = each.value.enable_immutability_policy
  immutability_period_days          = each.value.immutability_period_days
  immutability_policy_state         = each.value.immutability_policy_state
  enable_container_delete_retention = each.value.enable_container_delete_retention
  container_delete_retention_days   = each.value.container_delete_retention_days
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  private_dns_zone_id               = each.value.private_dns_zone_id
  #prevent_storage_account_deletion = each.value.prevent_storage_account_deletion
  tags = each.value.tags

  depends_on = [module.vnet, module.law]
}

#Deploy Azure Function Apps with VNet integration and storage account binding
module "function_app" {
  source        = "../../modules/function_app"
  function_apps = var.enable_function_app ? local.function_apps : {}
  rg_name       = data.azurerm_resource_group.rg.name
  location      = data.azurerm_resource_group.rg.location
  env           = var.env
  depends_on    = [module.storage_account, module.azure_identity, module.law]
}

# Deploy Azure Key Vaults with private endpoints and RBAC authorization
module "kv" {
  for_each = var.enable_kv ? local.kv_configs : {}

  source                          = "../../modules/kv"
  name_prefix                     = each.key
  rg_name                         = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  env                             = var.env
  sku_name                        = each.value.sku_name
  purge_protection_enabled        = each.value.purge_protection_enabled
  soft_delete_retention_days      = each.value.soft_delete_retention_days
  enable_rbac_authorization       = each.value.enable_rbac_authorization
  subnet_id                       = each.value.subnet_id
  vnet_id                         = each.value.vnet_id
  log_analytics_workspace_id      = each.value.log_analytics_workspace_id
  public_network_access_enabled   = each.value.public_network_access_enabled
  enable_diagnostics              = each.value.enable_kv_diagnostics
  log_categories                  = each.value.log_categories
  metric_categories               = each.value.metric_categories
  private_endpoint_enabled        = each.value.private_endpoint_enabled # Set to true if you want to enable private endpoint
  tags                            = each.value.tags
  enable_for_disk_encryption      = each.value.enable_for_disk_encryption
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_template_deployment = each.value.enabled_for_template_deployment
  private_dns_zone_id             = each.value.private_dns_zone_id
  #prevent_kv_deletion             = each.value.prevent_kv_deletion 

  depends_on = [module.vnet, module.law]
}

# Deploy Azure Kubernetes Service clusters with default and additional node pools
module "aks" {
  for_each = var.enable_aks ? local.aks_configs : {}

  source = "../../modules/aks"

  aks_name_prefix                   = each.key
  rg_name                           = data.azurerm_resource_group.rg.name
  location                          = data.azurerm_resource_group.rg.location
  env                               = var.env
  kubernetes_version                = each.value.kubernetes_version
  role_based_access_control_enabled = each.value.role_based_access_control_enabled
  local_account_disabled            = each.value.local_account_disabled
  private_cluster                   = each.value.private_cluster
  network_plugin                    = each.value.network_plugin
  load_balancer_sku                 = each.value.load_balancer_sku
  os_sku                            = each.value.os_sku
  node_os_disk_type                 = each.value.node_os_disk_type
  enable_host_encryption            = each.value.encryption_host
  vnet_subnet_id                    = each.value.vnet_subnet_id
  default_node_pool                 = each.value.default_node_pool
  additional_node_pools             = each.value.additional_node_pools
  aks_dns_service_ip                = each.value.aks_dns_service_ip
  aks_service_cidr                  = each.value.aks_service_cidr
  network_data_plane                = each.value.network_data_plane
  network_plugin_mode               = each.value.network_plugin_mode
  log_analytics_workspace_id        = try(module.law[0].log_analytics_workspace_id, "")
  UserAssigned_identity             = each.value.UserAssigned_identity
  tags                              = each.value.tags

  depends_on = [module.vnet, module.law]
}

# Deploy PostgreSQL Flexible Server with high availability and private networking
module "postgresql_flex" {
  source                        = "../../modules/postgresql_flex"
  for_each                      = var.enable_postgresql_flex ? local.postgresql_servers : {}
  psql_server_name_prefix       = each.key
  env                           = var.env
  location                      = data.azurerm_resource_group.rg.location
  rg_name                       = data.azurerm_resource_group.rg.name
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
  log_analytics_workspace_id    = try(module.law[0].log_analytics_workspace_id, "")
  log_categories                = each.value.log_categories
  metric_categories             = each.value.metric_categories
  tags                          = each.value.tags
  db_name                       = each.value.db_name
  private_dns_zone_id           = each.value.private_dns_zone_id
  enable_diagnostics            = each.value.enable_diagnostics

  depends_on = [module.vnet, module.law]
}

# Deploy API Management service with VNet integration and diagnostic logging
module "apim" {
  for_each                   = var.enable_apim ? local.apim_configs : {}
  source                     = "../../modules/apim"
  apim_name_prefix           = each.key
  environment                = var.env
  rg_name                    = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  subnet_id                  = each.value.subnet_id
  publisher_name             = each.value.publisher_name
  publisher_email            = each.value.publisher_email
  sku_name                   = each.value.sku_name
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  tags                       = each.value.tags

  depends_on = [module.vnet, module.law]
}

# # main.tf (root module)
# module "api_management_apis" {
#   source              = "../../modules/apis"
#   apis                = local.transformed_apis
#   resource_group_name = data.azurerm_resource_group.rg.name
#   api_management_name = module.apim["apim3"].apim_name_prefix
# }

# Deploy Redis Cache with private endpoint for distributed caching
module "redis" {
  for_each = var.enable_redis_cache ? local.redis_cache : {}

  source                     = "../../modules/redis"
  redis_name_prefix          = each.key
  location                   = data.azurerm_resource_group.rg.location
  rg_name                    = data.azurerm_resource_group.rg.name
  env                        = var.env
  subnet_id                  = each.value.subnet_id
  redis_capacity             = each.value.redis_capacity
  redis_family               = each.value.redis_family
  redis_sku_name             = each.value.redis_sku_name
  redis_minimum_tls_version  = each.value.redis_minimum_tls_version
  redis_version              = each.value.redis_version
  vnet_id                    = each.value.vnet_id
  enable_redis_diagnostics   = each.value.enable_redis_diagnostics
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  #log_categories             = each.value.log_categories
  private_dns_zone_id      = each.value.private_dns_zone_id
  private_endpoint_enabled = each.value.private_endpoint_enabled
  tags                     = each.value.tags

  depends_on = [module.vnet, module.law]
}

# Deploy SQL Managed Instance with diagnostic settings and database creation
module "sqlmi" {
  source                       = "../../modules/sqlmi"
  for_each                     = var.enable_sqlmi ? local.sqlmi_servers : {}
  env                          = var.env
  sqlmi_server_name_prefix     = each.key
  rg_name                      = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  subnet_id                    = each.value.subnet_id
  sqlmi_db_name                = each.value.sqlmi_db_name
  enable_sqlmi_diagnostics     = each.value.enable_sqlmi_diagnostics
  log_analytics_workspace_id   = try(module.law[0].log_analytics_workspace_id, "")
  metric_categories            = each.value.metric_categories
  network_security_group_name  = each.value.network_security_group_name
  short_term_retention_days    = each.value.short_term_retention_days
  tags                         = each.value.tags

  depends_on = [module.vnet, module.law]
}

# Deploy Log Analytics Workspace for centralized logging and monitoring
module "law" {
  source            = "../../modules/log_analytics_workspace"
  count             = var.enable_log_analytics_workspace ? 1 : 0
  rg_name           = data.azurerm_resource_group.rg.name
  location          = data.azurerm_resource_group.rg.location
  env               = var.env
  law_name          = "claims"
  law_sku           = "PerGB2018" # Use the appropriate SKU for your use
  retention_in_days = 30
  tags = {
    environment = var.env
    created_by  = "terraform"
  }
}

# Deploy Azure Document Intelligence (Form Recognizer) for document processing
module "documentIntellegence" {
  source                     = "../../modules/documentIntelligence"
  for_each                   = var.enable_di_account ? local.di_account : {}
  di_name_prefix             = each.value.di_name_prefix
  env                        = var.env
  location                   = var.location
  rg_name                    = data.azurerm_resource_group.rg.name
  sku_name                   = each.value.sku_name
  kind                       = each.value.kind
  vnet_id                    = each.value.vnet_id
  subnet_id                  = each.value.snet_id
  custom_subdomain_name      = each.value.custom_subdomain_name
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  private_endpoint_enabled   = each.value.private_endpoint_enabled
  private_dns_zone_id        = each.value.private_dns_zone_id
  enable_diagnostics         = each.value.enable_diagnostics
  tags                       = each.value.tags

  depends_on = [module.vnet, module.law]
}


# Deploy Azure OpenAI service with private endpoint and custom subdomain
module "azure_openai" {
  source                     = "../../modules/azure_openai"
  for_each                   = var.enable_azure_openai ? local.azure_openai : {}
  env                        = var.env
  name_prefix                = each.key
  location                   = each.value.location
  pe_location                = data.azurerm_resource_group.rg.location
  rg_name                    = data.azurerm_resource_group.rg.name
  sku_name                   = each.value.sku_name
  kind                       = each.value.kind
  custom_subdomain           = each.value.custom_subdomain
  subnet_id                  = each.value.subnet_id
  vnet_id                    = each.value.vnet_id
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  private_endpoint_enabled   = each.value.private_endpoint_enabled
  private_dns_zone_id        = each.value.private_dns_zone_id
  enable_diagnostics         = each.value.enable_diagnostics
  tags                       = each.value.tags

  depends_on = [module.vnet, module.law]
}

# Deploy Azure Machine Learning workspace linked to Key Vault and Storage Account
module "azure_machine_learning" {
  source                     = "../../modules/azure-machine-learning"
  for_each                   = var.enable_aml_workspace ? local.aml_workspace : {}
  env                        = var.env
  location                   = var.location
  rg_name                    = data.azurerm_resource_group.rg.name
  ml_workspace_nameprefix    = each.value.ml_workspace_nameprefix
  vnet_id                    = each.value.vnet_id
  subnet_id                  = each.value.subnet_id
  key_vault_id               = each.value.key_vault_id
  storage_account_id         = each.value.storage_account_id
  application_insights_id    = module.AppInsights[0].application_insights_id
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  private_endpoint_enabled   = each.value.private_endpoint_enabled
  private_dns_zone_id        = each.value.private_dns_zone_id
  enable_diagnostics         = each.value.enable_diagnostics
  tags                       = each.value.tags

  depends_on = [module.kv, module.storage_account, module.AppInsights, module.law]
}

# Deploy Azure Cosmos DB for MongoDB vCore with geo-replication
module "azure_documentdb" {
  source                   = "../../modules/azure_documentdb"
  for_each                 = var.enable_azure_documentdb ? local.azure_documentdb : {}
  env                      = var.env
  cluster_name_prefix      = each.key
  location                 = var.location
  rg_name                  = data.azurerm_resource_group.rg.name
  administrator_username   = each.value.administrator_username
  administrator_password   = each.value.administrator_password
  shard_count              = each.value.shard_count
  compute_tier             = each.value.compute_tier
  high_availability_mode   = each.value.high_availability_mode
  storage_size_in_gb       = each.value.storage_size_in_gb
  mongodb_version          = each.value.mongodb_version
  geo_replica_location     = each.value.geo_replica_location
  kv_id                    = module.kv["kv005-cind-claims"].kv_id
  vnet_id                  = each.value.vnet_id
  subnet_id                = each.value.subnet_id
  private_dns_zone_id      = each.value.private_dns_zone_id
  private_endpoint_enabled = each.value.private_endpoint_enabled

  tags = each.value.tags

  depends_on = [module.kv, module.vnet]
}

# Create user-assigned managed identities for secure resource authentication
module "azure_identity" {
  source        = "../../modules/azure_identity"
  for_each      = var.enable_UserAssignedIdenti ? local.UserAssignedIdenti : {}
  identity_name = each.value.identity_name
  env           = var.env
  location      = var.location
  rg_name       = data.azurerm_resource_group.rg.name
  tags          = each.value.tags

  depends_on = [module.vnet]
}

# Deploy Cosmos DB with MongoDB API and private endpoint
module "cosmosdb" {
  source                = "../../modules/cosmosdb"
  for_each              = var.enable_cosmos ? local.cosmos_configs : {}
  env                   = var.env
  cosmosdb_name_prefix  = each.key
  location              = var.location
  rg_name               = data.azurerm_resource_group.rg.name
  offer_type            = each.value.offer_type
  cosmos_kind           = each.value.cosmos_kind
  geo_location1         = each.value.geo_location1
  vnet_id               = each.value.vnet_id
  subnet_id             = each.value.subnet_id
  UserAssigned_identity = each.value.UserAssigned_identity
  #cosmosdb_name         = "mongodb"
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  tags                       = each.value.tags
  private_endpoint_enabled   = each.value.private_endpoint_enabled
  private_dns_zone_id        = each.value.private_dns_zone_id
  enable_diagnostics         = each.value.enable_diagnostics
  depends_on                 = [module.azure_identity, module.vnet, module.law]
}

# Deploy Application Insights for application performance monitoring
module "AppInsights" {
  count                      = var.enable_appinsights ? 1 : 0
  source                     = "../../modules/appinsights"
  name_prefix                = "appinsight-claims-test1"
  env                        = var.env
  location                   = var.location
  rg_name                    = data.azurerm_resource_group.rg.name
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  tags = {
    Description = "Pre-Prod Application Insights"
    LAW         = "pre-prod-law"
  }

  depends_on = [module.law]
}

locals {
  diagnostics_settings_configs = {
  }
}

module "kv_diag" {
  for_each                   = var.enable_diagnostics_settings ? local.diagnostics_settings_configs : {}
  source                     = "../../modules/diagnostic_setting"
  name                       = format("%s-%s-diagnostic-module", var.env, each.value.name)
  target_resource_id         = each.value.target_resource_id
  log_analytics_workspace_id = try(module.law[0].log_analytics_workspace_id, "")
  log_categories             = each.value.log_categories
  metric_categories          = each.value.metric_categories
  depends_on                 = [module.law]
}

locals {
  pvt_endpoints_configs = {
  }
}

module "private_endpoints" {
  source = "../../modules/pe"

  for_each = var.enable_private_endpoints ? local.pvt_endpoints_configs : {}

  name                           = each.key
  location                       = var.location
  resource_group_name            = data.azurerm_resource_group.rg.name
  private_connection_resource_id = each.value.private_connection_resource_id
  subresource_name               = each.value
  vnet_id                        = each.value.vnet_id
  subnet_id                      = each.value.subnet_id
}

locals {
  rbac_configs = {
    kv = {
      scope                = try(module.kv["kv005-cind-claims"].key_vault_id, "")
      principal_id         = try(module.azure_identity["cosmos"].user_assigned_identity_principal_id, "")
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

module "rbac1" {
  for_each             = var.enable_rbac ? local.rbac_configs : {}
  source               = "../../modules/rbac"
  scope                = module.kv["kv005-cind-claims"].key_vault_id
  principal_id         = module.azure_identity["cosmos"].user_assigned_identity_principal_id
  role_definition_name = "Key Vault Secrets User"
  depends_on           = [module.kv, module.azure_identity]
}


module "vnet_peering" {
  source = "../../modules/vnet_peering"

  enable_peering = false

  hub_vnets = {
    hub1 = {
      name            = try(module.vnet["cind-claims"].vnet_name, "") #Vnet name
      resource_group  = try(data.azurerm_resource_group.rg.name, "")  #vnet rg name
      vnet_id         = try(module.vnet["cind-claims"].vnet_id, "")   #"vnet ID. /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"
      subscription_id = ""                                            #<sub-id>
    }
  }

  spoke_vnets = {
    spoke1 = {
      name            = try(module.vnet["vnet004"].vnet_name, "")    #Vnet name
      resource_group  = try(data.azurerm_resource_group.rg.name, "") #vnet rg name
      vnet_id         = try(module.vnet["vnet004"].vnet_id, "")      #"vnet ID. /subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"
      subscription_id = ""                                           #<sub-id>
    }
  }
}