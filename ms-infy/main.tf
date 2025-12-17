
########################################
# Guardrail: block unintended deletions
########################################

locals {
  # Flatten nested VNets map for stable for_each keys [2](https://microsoft.sharepoint.com/teams/Aznet/_layouts/15/Doc.aspx?sourcedoc=%7BD04AF3DA-9ED9-433A-A429-519F96D176B8%7D&file=SDN%20Bootcamp%20-%20Azure%20Virtual%20Network%20Manager.pptx&action=edit&mobileredirect=true&DefaultItemOpen=1)
  vnet_flat = merge([
    for outer_k, outer_v in var.virtual_networks : {
      for vnet_k, vnet in outer_v :
      vnet_k => merge(vnet, { _outer_key = outer_k })
    }
  ]...)

  any_vnet_disabled = anytrue([for k, v in local.vnet_flat : !try(v.enabled, true)])

  any_subnet_disabled = anytrue(flatten([
    for vnet_k, vnet in local.vnet_flat : [
      for sn_k, sn in vnet.subnet_configs : !try(sn.enabled, true)
    ]
  ]))

  any_nsg_disabled   = anytrue([for k, n in var.nsg_configs : !try(n.enabled, true)])
  any_assoc_disabled = anytrue([for k, a in var.nsg_associations : !try(a.enabled, true)])

  any_delete_intent = (
    !var.enabled
    || local.any_vnet_disabled
    || local.any_subnet_disabled
    || local.any_nsg_disabled
    || local.any_assoc_disabled
  )
}

resource "terraform_data" "destroy_guard" {
  input = {
    enabled           = var.enabled
    allow_destroy     = var.allow_destroy
    any_delete_intent = local.any_delete_intent
  }

  lifecycle {
    precondition {
      condition     = !local.any_delete_intent || (local.any_delete_intent && var.allow_destroy)
      error_message = "Deletion blocked. You have delete intent (global enabled=false OR some resources enabled=false) but allow_destroy=false. Set allow_destroy=true to proceed."
    }
  }
}

########################################
# Resource Group: create (AVM) or import existing
########################################

# AVM composition pattern: RG + VNet + NSG modules together 
module "rg" {
  count = (var.enabled && var.resource_group.enabled && var.resource_group.create) ? 1 : 0

  # NOTE: Keep this as AVM source + pinned version.
  # If your registry name differs, only change source/version; do NOT change tfvars schema.
  source = "Azure/avm-res-resources-resourcegroup/azurerm"
  # Bump to a version that supports azurerm >=3.71 and <5.0 so it can interoperate with other modules
  version = "0.2.1"

  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = var.resource_group.tags
}

data "azurerm_resource_group" "rg" {
  count = (var.enabled && var.resource_group.enabled && !var.resource_group.create) ? 1 : 0
  name  = var.resource_group.name
}

locals {
  rg_name     = var.resource_group.create ? one(module.rg[*].name) : one(data.azurerm_resource_group.rg[*].name)
  rg_location = var.resource_group.create ? one(module.rg[*].location) : one(data.azurerm_resource_group.rg[*].location)
}

########################################
# NSG: create with AVM OR import existing
########################################

module "nsg" {
  for_each = (var.enabled) ? {
    for k, n in var.nsg_configs : k => n
    if try(n.enabled, true) && n.create_nsg
  } : {}

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  name                = each.value.nsg_name
  resource_group_name = local.rg_name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  tags                = merge(var.resource_group.tags, try(each.value.tags, {}))

  # Module expects a map(object) keyed by rule name. Convert list -> map when provided.
  security_rules = length(try(each.value.security_rules, [])) > 0 ? { for r in each.value.security_rules : r.name => r } : {}

}

data "azurerm_network_security_group" "existing" {
  for_each = (var.enabled) ? {
    for k, n in var.nsg_configs : k => n
    if try(n.enabled, true) && !n.create_nsg
  } : {}

  name                = coalesce(try(each.value.existing_nsg_name, null), each.value.nsg_name)
  resource_group_name = coalesce(try(each.value.existing_rg_name, null), local.rg_name)
}

locals {
  nsg_ids = {
    for k, n in var.nsg_configs :
    k => (
      !try(n.enabled, true)
      ? null
      : n.create_nsg
      ? module.nsg[k].resource_id
      : coalesce(try(n.existing_nsg_id, null), data.azurerm_network_security_group.existing[k].id)
    )
  }
}

########################################
# VNet + Subnets: AVM VNet module (subnets as child resources)
########################################

module "vnet" {
  for_each = (var.enabled) ? {
    for k, v in local.vnet_flat : k => v
    if try(v.enabled, true)
  } : {}

  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.0"

  name                = each.key
  resource_group_name = local.rg_name
  location            = each.value.location

  address_space = [each.value.address_space]
  # Module expects an object: { dns_servers = set(string) } or null.
  # Convert incoming list to the expected object when present, otherwise pass null.
  dns_servers = try(each.value.dns_servers, null) != null ? { dns_servers = toset(each.value.dns_servers) } : null

  #enable_ddos_protection = each.value.enable_ddos_protection

  tags = merge(var.resource_group.tags, try(each.value.tags, {}))

  # Only enabled subnets are created.
  # Module expects a map(object). We preserve the original keys as the map keys and
  # ensure each subnet object contains a `name` attribute (required by the module).
  subnets = {
    for sn_k, sn in each.value.subnet_configs : sn_k => {
      name = sn_k

      # address: support single address_prefix or pre-populated address_prefixes
      address_prefixes = sn.address_prefix != null ? [sn.address_prefix] : try(sn.address_prefixes, null)

      # service_endpoints: module expects a set(string)
      service_endpoints = try(sn.service_endpoints, null) != null ? toset(sn.service_endpoints) : null

      # delegation: module expects a list(object) when present
      delegation = try(sn.delegation, null) != null ? [sn.delegation] : null

      private_endpoint_network_policies = try(sn.private_endpoint_network_policies, null)
      private_link_service_network_policies_enabled = try(sn.private_link_service_network_policies_enabled, true)

      # route_table can be provided either as { id = ... } or via route_table_id in tfvars
      route_table = try(sn.route_table, null) != null ? sn.route_table : (try(sn.route_table_id, null) != null ? { id = sn.route_table_id } : null)

      nat_gateway = try(sn.nat_gateway, null)
      network_security_group = try(sn.network_security_group, null)
      service_endpoint_policies = try(sn.service_endpoint_policies, null)
      default_outbound_access_enabled = try(sn.default_outbound_access_enabled, null)
      sharing_scope = try(sn.sharing_scope, null)

      timeouts = try(sn.timeouts, null)
      role_assignments = try(sn.role_assignments, null)
    } if try(sn.enabled, true)
  }
}

########################################
# Subnet <-> NSG associations: fully tfvars-driven
########################################

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = (var.enabled) ? {
    for k, a in var.nsg_associations : k => a
    if try(a.enabled, true)
  } : {}

  subnet_id                 = module.vnet[each.value.vnet_key].subnets[each.value.subnet_key].resource_id
  network_security_group_id = local.nsg_ids[each.value.nsg_key]
}
