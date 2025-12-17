
# PORTAL_TO_TFVARS.md (Portal tabs -> tfvars)

## Resource Group (Portal: Basics)
- Create vs existing: resource_group.create
- Name: resource_group.name
- Location: resource_group.location
- Tags: resource_group.tags

## Virtual Network (Portal: Basics)
- VNet name: virtual_networks.<outer>.<vnetKey>  (vnetKey)
- Create toggle: virtual_networks.<outer>.<vnetKey>.create
- Location: virtual_networks.<outer>.<vnetKey>.location
- Tags: virtual_networks.<outer>.<vnetKey>.tags

## Virtual Network (Portal: IP Addresses)
- Address space: virtual_networks.<outer>.<vnetKey>.address_space
- Subnets: virtual_networks.<outer>.<vnetKey>.subnet_configs

## Virtual Network (Portal: DNS Servers)
- DNS servers: virtual_networks.<outer>.<vnetKey>.dns_servers

## Virtual Network (Portal: DDoS Protection)
- Toggle: virtual_networks.<outer>.<vnetKey>.enable_ddos_protection

---

## Subnet (Portal: Subnets)
- Subnet name: ...subnet_configs.<subnetKey>
- Presence controls: include the subnet entry to create it; remove or comment out the subnet entry to delete it.
- Address range: ...subnet_configs.<subnetKey>.address_prefix

## Subnet (Portal: Service endpoints)
- Service endpoints: ...subnet_configs.<subnetKey>.service_endpoints

## Subnet (Portal: Delegation)
- Delegation: ...subnet_configs.<subnetKey>.delegation

## Subnet (Portal: Network policies)
- Private endpoint policies: ...private_endpoint_network_policies_enabled
- Private link service policies: ...private_link_service_network_policies_enabled

---

## NSG (Portal: Basics)
- Create vs import: nsg_configs.<nsgKey>.create
- Create toggle: nsg_configs.<nsgKey>.create
- Name: nsg_configs.<nsgKey>.nsg_name

## NSG (Portal: Inbound/Outbound rules)
- Rules list: nsg_configs.<nsgKey>.security_rules

---

## NSG <-> Subnet association (Portal: Subnet > Network security group)
Use associations for maximum flexibility:
- nsg_associations.<assocKey> = { vnet_key, subnet_key, nsg_key, create }

This lets you attach:
- 1 NSG to many subnets
- 2 NSGs across different subnets
- imported NSG to any subnet you choose
