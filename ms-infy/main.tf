
########################################
# Guardrail: block unintended deletions
########################################

// Note: effective_* locals are defined in `ms-infy/locals.tf` so they are
// available to the rest of this module and can be overridden by `.tfvars`.
locals {
  # Flatten nested VNets map for stable for_each keys (prefer var.* when
  # provided; otherwise use `env/locals.tf` defaults via
  # `local.effective_virtual_networks`).
  # NOTE: Use the virtual_networks map's original keys as the module
  # iteration keys (this keeps `module.vnet` entries keyed by the
  # `locals.virtual_networks` keys such as `vnet1`, which is useful when
  # downstream maps (like `nsg_associations`) reference VNets by that
  # original key). We still capture the explicit `name` (if present) on
  # each entry so callers can refer to the human-friendly name when
  # desired.
  vnet_flat = {
    for vnet_k, vnet in local.effective_virtual_networks :
    vnet_k => merge(vnet, { _vnet_key = vnet_k, _vnet_name = try(vnet.name, null) })
  }

  # Helper map: allow callers to provide either the original map key
  # (e.g. "vnet1") or the explicit `name` (e.g. "cind-claims"). This
  # maps the canonical lookup key -> original map key so our module
  # lookup expressions can resolve either form.
  vnet_name_to_key = {
    for k, v in local.vnet_flat : coalesce(try(v._vnet_name, null), k) => k
  }

  any_vnet_disabled = anytrue([for k, v in local.vnet_flat : !try(v.create, true)])

  any_subnet_disabled = anytrue(flatten([
    for vnet_k, vnet in local.vnet_flat : [
      for sn_k, sn in vnet.subnet_configs : !try(sn.create, true)
    ]
  ]))

  any_nsg_disabled = anytrue([for k, n in local.effective_nsg_configs : !try(n.create, true)])
}

locals {
  # Map from "vnet_key.subnet_key" -> nsg id for associations. Used
  # to populate the subnet.networkSecurityGroup property so the azapi subnet
  # body matches the association resource (prevents provider-side flips).
  subnet_nsg_map = {
    for k, a in local.effective_nsg_associations :
    "${lookup(local.vnet_name_to_key, a.vnet_key, a.vnet_key)}.${a.subnet_key}" => try(local.nsg_ids[a.nsg_key], null)
  }
}

########################################
# Resource Group: create (AVM) or import existing
########################################

# AVM composition pattern: RG + VNet + NSG modules together 
module "rg" {
  count = local.effective_resource_group.create ? 1 : 0

  # NOTE: Keep this as AVM source + pinned version.
  # If your registry name differs, only change source/version; do NOT change tfvars schema.
  source = "Azure/avm-res-resources-resourcegroup/azurerm"
  # Bump to a version that supports azurerm >=3.71 and <5.0 so it can interoperate with other modules
  version = "0.2.1"

  name     = local.effective_resource_group.name
  location = local.effective_resource_group.location
  tags     = local.effective_resource_group.tags
}

data "azurerm_resource_group" "rg" {
  count = (!local.effective_resource_group.create) ? 1 : 0
  name  = local.effective_resource_group.name
}

locals {
  rg_name = local.effective_resource_group.create ? (
    local.effective_resource_group.create ? one(module.rg[*].name) : one(data.azurerm_resource_group.rg[*].name)
  ) : local.effective_resource_group.name

  rg_location = local.effective_resource_group.create ? (
    local.effective_resource_group.create ? one(module.rg[*].location) : one(data.azurerm_resource_group.rg[*].location)
  ) : local.effective_resource_group.location

  rg_id = local.effective_resource_group.create ? one(module.rg[*].resource_id) : one(data.azurerm_resource_group.rg[*].id)
}

########################################
# NSG: create with AVM OR import existing
########################################

module "nsg" {
  for_each = { for k, n in local.effective_nsg_configs : k => n if try(n.create, true) }

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  name                = each.value.nsg_name
  resource_group_name = local.rg_name
  location            = coalesce(try(each.value.location, null), local.rg_location)
  # If there are no tags, send `null` instead of an empty map to avoid a
  # one-time provider diff where Azure reflects an empty tag set.
  tags = length(merge(local.effective_resource_group.tags, try(each.value.tags, {}))) > 0 ? merge(local.effective_resource_group.tags, try(each.value.tags, {})) : null

  # Module expects a map(object) keyed by rule name. Convert list -> map when provided.
  security_rules = length(try(each.value.security_rules, [])) > 0 ? { for r in each.value.security_rules : r.name => r } : {}

}

data "azurerm_network_security_group" "existing" {
  for_each = { for k, n in local.effective_nsg_configs : k => n if !try(n.create, true) }

  name                = coalesce(try(each.value.existing_nsg_name, null), try(each.value.nsg_name, null))
  resource_group_name = coalesce(try(each.value.existing_rg_name, null), local.rg_name)
}

locals {
  nsg_ids = {
    for k, n in local.effective_nsg_configs :
    k => (
      try(n.create, true) ? module.nsg[k].resource_id : coalesce(try(n.existing_nsg_id, null), try(data.azurerm_network_security_group.existing[k].id, null), null)
    )
  }
}

########################################
# VNet + Subnets: AVM VNet module (subnets as child resources)
########################################

module "vnet" {
  for_each = { for k, v in local.vnet_flat : k => v if try(v.create, true) }

  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.0"

  # The AVM module expects the VNet resource name. Prefer the explicit
  # `name` attribute from the map; fall back to the for_each key to preserve
  # backward compatibility.
  name                = try(each.value.name, each.key)
  resource_group_name = local.rg_name
  location            = each.value.location

  address_space = [each.value.address_space]
  # Module expects an object: { dns_servers = set(string) } or null.
  # Convert incoming list to the expected object when present, otherwise pass null.
  dns_servers = try(each.value.dns_servers, null) != null ? { dns_servers = toset(each.value.dns_servers) } : null

  #enable_ddos_protection = each.value.enable_ddos_protection
  enable_telemetry = false
  tags             = merge(local.effective_resource_group.tags, try(each.value.tags, {}))

  # Subnets are created when they exist in the `subnet_configs` map. Removing
  # or commenting out a subnet entry in `ms-infy/locals.tf` will remove
  # (destroy) that subnet on apply.
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

      private_endpoint_network_policies             = try(sn.private_endpoint_network_policies, null)
      private_link_service_network_policies_enabled = try(sn.private_link_service_network_policies_enabled, true)

      # route_table can be provided either as { id = ... } or via route_table_id in tfvars
      route_table = try(sn.route_table, null) != null ? sn.route_table : (try(sn.route_table_id, null) != null ? { id = sn.route_table_id } : null)

      nat_gateway = try(sn.nat_gateway, null)
      # Network security groups are managed by the separate
      # `azurerm_subnet_network_security_group_association` resources below
      # (driven from var.nsg_associations). Avoid setting the
      # `networkSecurityGroup` property in the subnet body to prevent
      # provider-side churn where the attribute flips between null and an id.
      service_endpoint_policies       = try(sn.service_endpoint_policies, null)
      default_outbound_access_enabled = try(sn.default_outbound_access_enabled, null)
      sharing_scope                   = try(sn.sharing_scope, null)

      # When an association exists for this vnet.subnet, explicitly set the
      # subnet's networkSecurityGroup property so the azapi subnet resource's
      # body matches the association resource and avoids churn.
      network_security_group = lookup(local.subnet_nsg_map, "${each.key}.${sn_k}", null) != null ? { id = lookup(local.subnet_nsg_map, "${each.key}.${sn_k}", null) } : null

      timeouts         = try(sn.timeouts, null)
      role_assignments = try(sn.role_assignments, null)
    }
  }
}

########################################
# Subnet <-> NSG associations: default-driven from `env/locals.tf` but
# overridable via tfvars; associations come from
# `local.effective_nsg_associations` (prefer `var.nsg_associations` when set).
########################################

resource "azurerm_subnet_network_security_group_association" "assoc" {
  # Associations are created for every entry present in `local.effective_nsg_associations`.
  # Removing an entry from the map (e.g., comment/remove it from `ms-infy/locals.tf`) will
  # cause Terraform to plan the association's destruction on the next apply.
  for_each = { for k, a in local.effective_nsg_associations : k => a }

  subnet_id                 = module.vnet[lookup(local.vnet_name_to_key, each.value.vnet_key, each.value.vnet_key)].subnets[each.value.subnet_key].resource_id
  network_security_group_id = local.nsg_ids[each.value.nsg_key]
}

# module "keyvault" {
#   source  = "Azure/avm-res-keyvault-vault/azurerm"
#   version = "0.10.2"
#   # insert the 4 required variables here
#   name                            = "kv002-test-infy"
#   location                        = local.rg_location
#   resource_group_name             = local.rg_name
#   tenant_id                       = var.tenant_id
#   soft_delete_retention_days      = 7
#   purge_protection_enabled        = true
#   legacy_access_policies_enabled  = false #true will enable access policy. false will enable rbac
#   enabled_for_deployment          = true
#   enabled_for_disk_encryption     = true
#   enabled_for_template_deployment = true
#   public_network_access_enabled   = false
#   enable_telemetry                = false
#   network_acls = {
#     bypass         = "AzureServices"
#     default_action = "Deny"
#     # Resolve the module.vnet key robustly: prefer an explicit `name` attribute
#     # when present in the original vnet map, else fall back to the original map key.
#     virtual_network_subnet_ids = [
#       module.vnet[lookup(local.vnet_name_to_key, "vnet1", "vnet1")].subnets["cind-pvt"].resource_id
#     ]
#   }
#   private_endpoints = {
#     "kv-pe" = {
#       name                            = "pvt-endpoint-kv002-test-infy" # optional
#       subnet_resource_id              = module.vnet[lookup(local.vnet_name_to_key, "vnet1", "vnet1")].subnets["cind-pvt"].resource_id
#       private_service_connection_name = "kv001-test-infy-psc" # optional
#       #private_dns_zone_resource_ids = [azurerm_private_dns_zone.kv_dns.id]            # optional set(string)
#       tags = { env = "test" } # optional
#     }
#   }
#   # Enable diagnostic settings for Key Vault. Replace the placeholder
#   # workspace_resource_id with your Log Analytics workspace resource id
#   # or provide an event hub / storage account id instead.
#   diagnostic_settings = {
#     "kv-diag" = {
#       name                  = "diag-kv002-test-infy"
#       workspace_resource_id = module.law.resource_id
#       # Optional: lists of log and metric categories to enable
#       log_categories    = ["AuditEvent"]
#       log_groups        = []
#       metric_categories = ["AllMetrics"]
#     }
#   }
#   tags = {
#     created_by = "terraform"
#   }
# }

# module "law" {
#   source                                    = "Azure/avm-res-operationalinsights-workspace/azurerm"
#   version                                   = "0.4.2"
#   name                                      = "IL-log-cind-test"
#   location                                  = local.rg_location
#   resource_group_name                       = local.rg_name
#   log_analytics_workspace_sku               = "PerGB2018"
#   log_analytics_workspace_retention_in_days = 30
#   enable_telemetry                          = false
#   tags = {
#     created_by = "terraform"
#   }
# }

# module "privatednszone" {
#   source           = "Azure/avm-res-network-privatednszone/azurerm"
#   version          = "0.4.3"
#   parent_id        = local.rg_id
#   domain_name      = "privatelink.vaultcore.azure.net"
#   enable_telemetry = false
# }