resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.vnet_name_prefix}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = [var.address_space]

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      enable = var.enable_ddos_protection
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
    }
  }

  dns_servers = var.dns_servers # ["10.0.0.4", "10.0.0.5"]

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.vnet_name_prefix
    }
  )
}


resource "azurerm_subnet" "subnet" {
  for_each             = var.subnet_configs
  name                 = "snet-${each.key}-${var.env}"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = each.value.service_endpoints
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

}

# resource "azurerm_network_security_group" "nsg" {
#   for_each            = { for snet_key, snet_value in var.subnet_configs : snet_key => snet_value if snet_value.create_nsg }
#   name                = "nsg-${each.key}"
#   location            = var.location
#   resource_group_name = var.rg_name
# }


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each                  = { for snet_key, snet_value in var.subnet_configs : snet_key => snet_value if snet_value.create_nsg }
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = var.nsg_default

}

resource "azurerm_route_table" "example" {
  for_each                      = { for snet_key, snet_value in var.subnet_configs : snet_key => snet_value if snet_value.create_route_table }
  name                          = "rt-${each.key}"
  location                      = var.location
  resource_group_name           = var.rg_name
  bgp_route_propagation_enabled = true
}

resource "azurerm_subnet_route_table_association" "example" {
  for_each       = { for snet_key, snet_value in var.subnet_configs : snet_key => snet_value if snet_value.create_route_table }
  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = azurerm_route_table.example[each.key].id
}

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = format("%s-ddos-plan", var.env)
  location            = var.location
  resource_group_name = var.rg_name
}
