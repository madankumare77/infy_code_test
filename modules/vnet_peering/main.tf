# Loop through all combinations: each spoke ↔ each hub
# We use a nested for expression to create a map of combinations

locals {
  peering_pairs = {
    for pair in flatten([
      for spoke_key, spoke in var.spoke_vnets : [
        for hub_key, hub in var.hub_vnets : {
          key       = "${spoke_key}-${hub_key}"
          spoke_key = spoke_key
          spoke     = spoke
          hub_key   = hub_key
          hub       = hub
        }
      ]
      ]) : pair.key => {
      spoke_key = pair.spoke_key
      spoke     = pair.spoke
      hub_key   = pair.hub_key
      hub       = pair.hub
    }
  }
}


# Spoke → Hub peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.enable_peering ? local.peering_pairs : {}

  name                      = "${each.value.spoke.name}-to-${each.value.hub.name}"
  resource_group_name       = each.value.spoke.resource_group
  virtual_network_name      = each.value.spoke.name
  remote_virtual_network_id = each.value.hub.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  provider = azurerm
}

# Hub → Spoke peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.enable_peering ? local.peering_pairs : {}

  name                      = "${each.value.hub.name}-to-${each.value.spoke.name}"
  resource_group_name       = each.value.hub.resource_group
  virtual_network_name      = each.value.hub.name
  remote_virtual_network_id = each.value.spoke.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  provider = azurerm
}


