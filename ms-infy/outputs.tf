
output "resource_group_name" {
  value = local.rg_name
}

output "vnet_ids" {
  value = { for k, v in module.vnet : k => v.resource_id }
}

output "subnet_ids" {
  value = {
    for vnet_k, v in module.vnet :
    vnet_k => { for sn_k, sn in v.subnets : sn_k => sn.resource_id }
  }
}

output "nsg_ids" {
  value = local.nsg_ids
}
