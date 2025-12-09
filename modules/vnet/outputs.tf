output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  value = { for snet_key, snet_value in azurerm_subnet.subnet : snet_key => snet_value.id }

}

output "nsg_name" {
  value = { for nsg_key, nsg_value in azurerm_network_security_group.nsg : nsg_key => nsg_value.name }
}