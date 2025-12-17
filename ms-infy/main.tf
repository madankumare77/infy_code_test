
########################################
# Resource Group: create OR existing (native)
# (No verified AVM Terraform module name found in search results.) [2](https://learn.microsoft.com/en-us/community/content/azure-verified-modules)
########################################
resource "azurerm_resource_group" "rg" {
  count    = var.resource_group.create ? 1 : 0
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = merge(var.tags, try(var.resource_group.tags, {}))
}

data "azurerm_resource_group" "rg" {
  count = var.resource_group.create ? 0 : 1
  name  = var.resource_group.name
}

locals {
  rg_name     = var.resource_group.create ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  rg_location = var.resource_group.create ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  rg_id       = var.resource_group.create ? azurerm_resource_group.rg[0].id : data.azurerm_resource_group.rg[0].id

}

########################################
# Log Analytics: create OR existing
# Create uses AVM module (confirmed by AVM TF labs). [1](https://learn.microsoft.com/en-us/samples/azure-samples/avm-terraform-labs/avm-terraform-labs/)
########################################

module "law_created" {
  source = "Azure/avm-res-operationalinsights-workspace/azurerm"
  count  = var.log_analytics.create ? 1 : 0

  name                = var.log_analytics.name
  resource_group_name = local.rg_name
  location            = coalesce(try(var.log_analytics.location, null), local.rg_location)

  # NOTE:
  # This AVM module version doesn't accept azurerm-native args like "sku" or "retention_in_days".
  # We'll rely on module defaults unless you map the module-specific variable names.
  tags = merge(var.tags, try(var.log_analytics.tags, {}))
}


data "azurerm_log_analytics_workspace" "law_existing" {
  count               = var.log_analytics.create ? 0 : 1
  name                = var.log_analytics.name
  resource_group_name = local.rg_name
}


locals {
  law_id = var.log_analytics.create ? try(module.law_created[0].resource_id, module.law_created[0].id) : data.azurerm_log_analytics_workspace.law_existing[0].id
}


########################################
# App Insights: create OR existing (native)
# (No verified AVM Terraform module source found in results I can cite.) [2](https://learn.microsoft.com/en-us/community/content/azure-verified-modules)
########################################
resource "azurerm_application_insights" "appi" {
  count               = var.application_insights.create ? 1 : 0
  name                = var.application_insights.name
  location            = coalesce(try(var.application_insights.location, null), local.rg_location)
  resource_group_name = local.rg_name
  application_type    = var.application_insights.application_type
  workspace_id        = local.law_id

  retention_in_days          = var.application_insights.retention_in_days
  sampling_percentage        = var.application_insights.sampling_percentage
  disable_ip_masking         = var.application_insights.disable_ip_masking
  internet_ingestion_enabled = var.application_insights.internet_ingestion_on
  internet_query_enabled     = var.application_insights.internet_query_on

  tags = merge(var.tags, try(var.application_insights.tags, {}))
}

data "azurerm_application_insights" "appi_existing" {
  count               = var.application_insights.create ? 0 : 1
  name                = var.application_insights.name
  resource_group_name = local.rg_name
}

locals {
  appi_id = var.application_insights.create ? azurerm_application_insights.appi[0].id : data.azurerm_application_insights.appi_existing[0].id
}

########################################
# VNets: create OR existing (AVM create)
########################################
locals {
  vnets_to_create = { for k, v in var.virtual_networks : k => v if v.create }
  vnets_existing  = { for k, v in var.virtual_networks : k => v if !v.create }
}


module "vnet_created" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  for_each = local.vnets_to_create

  name      = each.value.name
  parent_id = local.rg_id
  location  = each.value.location

  address_space = each.value.address_space

  #MUST be object (per your module variables.tf)
  dns_servers = {
    dns_servers = try(each.value.dns_servers, [])
  }

  # each subnet element must include "name"
  subnets = {
    for sk, s in each.value.subnets : s.name => {
      name              = s.name
      address_prefixes  = s.address_prefixes
      service_endpoints = try(s.service_endpoints, null)
      delegation        = try(s.delegation, null)
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

data "azurerm_virtual_network" "vnet_existing" {
  for_each            = local.vnets_existing
  name                = each.value.name
  resource_group_name = coalesce(try(each.value.resource_group_name, null), local.rg_name)
}

locals {
  existing_subnets_flat = merge([
    for vk, v in local.vnets_existing : {
      for sk, s in v.subnets :
      "${vk}.${sk}" => {
        subnet_name         = s.name
        vnet_name           = v.name
        resource_group_name = coalesce(try(v.resource_group_name, null), local.rg_name)
      }
    }
  ]...)
}

data "azurerm_subnet" "existing_subnet" {
  for_each             = local.existing_subnets_flat
  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.resource_group_name
}


locals {
  # VNet IDs (created + existing) with output fallback
  vnet_resource_id_by_key = merge(
    {
      for k, m in module.vnet_created :
      k => try(m.resource_id, m.vnet_id, m.id)
    },
    {
      for k, v in data.azurerm_virtual_network.vnet_existing :
      k => v.id
    }
  )

  # Subnet IDs for VNets created by AVM module (fallback to common AVM shapes)
  created_subnet_id_by_key = merge([
    for vk, v in local.vnets_to_create : {
      for sk, s in v.subnets :
      "${vk}.${sk}" => try(
        # common output names seen in AVM modules
        module.vnet_created[vk].subnet_ids[s.name],
        module.vnet_created[vk].subnet_resource_ids[s.name],

        # common nested object outputs seen in some versions
        module.vnet_created[vk].subnets[s.name].resource_id,
        module.vnet_created[vk].subnets[s.name].id
      )
    }
  ]...)

  # Final Subnet IDs (created + existing)
  subnet_id_by_key = merge(
    local.created_subnet_id_by_key,
    { for k, s in data.azurerm_subnet.existing_subnet : k => s.id }
  )
}

########################################
# NSGs: create OR existing (AVM create)
########################################
locals {
  nsgs_to_create = { for k, v in var.nsgs : k => v if v.create }
  nsgs_existing  = { for k, v in var.nsgs : k => v if !v.create }
}



module "nsg_created" {
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  for_each = local.nsgs_to_create

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  resource_group_name = coalesce(try(each.value.resource_group_name, null), local.rg_name)

  # ✅ MUST be map(object)
  security_rules = {
    for r in each.value.security_rules : r.name => r
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

data "azurerm_network_security_group" "nsg_existing" {
  for_each            = local.nsgs_existing
  name                = each.value.name
  resource_group_name = coalesce(try(each.value.resource_group_name, null), local.rg_name)
}


locals {
  nsg_id_by_key = merge(
    {
      for k, m in module.nsg_created :
      k => try(m.nsg_id, m.network_security_group_id, m.resource_id, m.id)
    },
    {
      for k, v in data.azurerm_network_security_group.nsg_existing :
      k => v.id
    }
  )
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each                  = var.nsg_associations
  subnet_id                 = local.subnet_id_by_key["${each.value.vnet_key}.${each.value.subnet_key}"]
  network_security_group_id = local.nsg_id_by_key[each.value.nsg_key]
}

########################################
# Private DNS Zones (AVM)
########################################

module "private_dns_zone" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  for_each = var.private_dns_zones

  domain_name = each.value.name
  parent_id   = local.rg_id

  # IMPORTANT: list of objects; each must have name (or vnetlinkname)
  virtual_network_links = [
    for vnet_key in each.value.vnet_keys : {
      name               = "${each.key}-${vnet_key}" # ✅ satisfies module validation
      virtual_network_id = local.vnet_resource_id_by_key[vnet_key]
    }
  ]

  tags = merge(var.tags, try(each.value.tags, {}))
}

########################################
# Identities (native)
########################################
resource "azurerm_user_assigned_identity" "uami" {
  for_each            = var.user_assigned_identities
  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  resource_group_name = local.rg_name
  tags                = merge(var.tags, try(each.value.tags, {}))
}

########################################
# Storage (native - portal tabs)
########################################
resource "azurerm_storage_account" "sa" {
  for_each            = var.storage_accounts
  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  resource_group_name = local.rg_name

  account_kind             = try(each.value.account_kind, "StorageV2")
  account_tier             = try(each.value.account_tier, "Standard")
  account_replication_type = each.value.account_replication_type
  access_tier              = try(each.value.access_tier, null)

  min_tls_version                   = try(each.value.advanced.min_tls_version, "TLS1_2")
  shared_access_key_enabled         = try(each.value.advanced.shared_access_key_enabled, false)
  https_traffic_only_enabled        = try(each.value.advanced.enable_https_traffic_only, true)
  allow_nested_items_to_be_public   = try(each.value.advanced.allow_nested_items_to_be_public, false)
  infrastructure_encryption_enabled = try(each.value.advanced.infrastructure_encryption_enabled, true)

  is_hns_enabled     = try(each.value.advanced.is_hns_enabled, false)
  nfsv3_enabled      = try(each.value.advanced.nfsv3_enabled, false)
  sftp_enabled       = try(each.value.advanced.sftp_enabled, false)
  local_user_enabled = try(each.value.advanced.local_user_enabled, false)

  public_network_access_enabled = try(each.value.networking.public_network_access_enabled, true)

  dynamic "network_rules" {
    for_each = (try(each.value.networking, null) == null) ? [] : [1]
    content {
      default_action             = try(each.value.networking.default_action, "Deny")
      bypass                     = try(each.value.networking.bypass, ["AzureServices"])
      ip_rules                   = try(each.value.networking.ip_rules, [])
      virtual_network_subnet_ids = try(each.value.networking.subnet_ids, [])
    }
  }

  blob_properties {
    versioning_enabled  = try(each.value.data_protection.versioning_enabled, true)
    change_feed_enabled = try(each.value.data_protection.change_feed_enabled, false)

    dynamic "delete_retention_policy" {
      for_each = try(each.value.data_protection.blob_soft_delete.enabled, false) ? [1] : []
      content { days = try(each.value.data_protection.blob_soft_delete.days, 7) }
    }

    dynamic "container_delete_retention_policy" {
      for_each = try(each.value.data_protection.container_soft_delete.enabled, false) ? [1] : []
      content { days = try(each.value.data_protection.container_soft_delete.days, 7) }
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

########################################
# Key Vault (native - portal tabs)
########################################
resource "azurerm_key_vault" "kv" {
  for_each            = var.key_vaults
  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  resource_group_name = local.rg_name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = try(each.value.sku_name, "standard")

  soft_delete_retention_days = try(each.value.soft_delete_retention_days, 7)
  purge_protection_enabled   = try(each.value.purge_protection_enabled, true)
  enable_rbac_authorization  = try(each.value.enable_rbac_authorization, true)

  public_network_access_enabled = try(each.value.networking.public_network_access_enabled, false)

  dynamic "network_acls" {
    for_each = (try(each.value.networking, null) == null) ? [] : [1]
    content {
      default_action             = try(each.value.networking.default_action, "Deny")
      bypass                     = try(each.value.networking.bypass, "AzureServices")
      ip_rules                   = try(each.value.networking.ip_rules, [])
      virtual_network_subnet_ids = try(each.value.networking.subnet_ids, [])
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

########################################
# ONE Generic Private Endpoint module (AVM) driven by private_endpoints
########################################
locals {
  pe_target_id = {
    for k, pe in var.private_endpoints :
    k => (
      try(pe.target_resource_id, null) != null ? pe.target_resource_id :
      pe.target_kind == "storage" ? azurerm_storage_account.sa[pe.target_key].id :
      pe.target_kind == "keyvault" ? azurerm_key_vault.kv[pe.target_key].id :
      pe.target_kind == "loganalytics" ? local.law_id :
      pe.target_kind == "appinsights" ? local.appi_id :
      null
    )
  }

  invalid_pe = [for k, pe in var.private_endpoints : k if local.pe_target_id[k] == null]
}

# resource "null_resource" "validate_pe" {
#   count = length(local.invalid_pe) > 0 ? 1 : 0
#   lifecycle {
#     precondition {
#       condition     = length(local.invalid_pe) == 0
#       error_message = "Invalid private_endpoints targets for: ${join(", ", local.invalid_pe)}."
#     }
#   }
# }


module "private_endpoint" {
  source   = "Azure/avm-res-network-privateendpoint/azurerm"
  for_each = var.private_endpoints

  # Required (AVM)
  name                = each.value.name
  location            = local.rg_location
  resource_group_name = local.rg_name

  subnet_resource_id             = local.subnet_id_by_key["${each.value.vnet_key}.${each.value.subnet_key}"]
  private_connection_resource_id = local.pe_target_id[each.key]
  network_interface_name         = coalesce(try(each.value.network_interface_name, null), "${each.value.name}-nic")

  # Commonly required/used in Private Endpoint modules:
  subresource_names = each.value.subresource_names

  # DNS integration (typical AVM pattern uses zone resource IDs)
  # NOTE: your module expects a list of private DNS zone resource IDs (not a nested "group" block).
  private_dns_zone_resource_ids = [
    module.private_dns_zone[each.value.private_dns_zone_key].private_dns_zone_id
  ]

  tags = merge(var.tags, try(each.value.tags, {}))
}


########################################
# Diagnostic settings (optional)
########################################
resource "azurerm_monitor_diagnostic_setting" "diag" {
  for_each                   = var.diagnostic_settings
  name                       = each.value.name
  target_resource_id         = each.value.target_resource_id
  log_analytics_workspace_id = each.value.log_analytics_workspace_id


  dynamic "enabled_log" {
    for_each = [
      for l in try(each.value.logs, []) : l
      if try(l.enabled, true)
    ]
    content {
      category       = try(enabled_log.value.category, null)
      category_group = try(enabled_log.value.category_group, null)
    }
  }


  dynamic "metric" {
    for_each = each.value.metrics
    content {
      category = metric.value.category
      enabled  = try(metric.value.enabled, true)
    }
  }

  lifecycle { ignore_changes = [log_analytics_destination_type] }
}
