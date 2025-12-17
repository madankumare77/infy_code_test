locals {
  virtual_networks = {
    vnet1 = {
      cind-claims = {
        create                 = true
        location               = "centralindia"
        address_space          = "100.122.96.0/24"
        enable_ddos_protection = false
        dns_servers            = ["168.63.129.16"]
        tags                   = { created_by = "terraform" }

        subnet_configs = {
          cind-pvt = {
            create            = true
            address_prefix    = "100.122.96.0/27"
            service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
          }

          cind-cosmosdb = {
            create            = true
            address_prefix    = "100.122.96.32/28"
            service_endpoints = ["Microsoft.AzureCosmosDB"]
          }

          cind-aiservice = {
            create         = true
            address_prefix = "100.122.96.48/28"
          }

          cind-funtionsapp = {
            create            = true
            address_prefix    = "100.122.96.64/28"
            service_endpoints = ["Microsoft.Storage", "Microsoft.Web"]
            delegation = {
              name = "functionapp"
              service_delegation = {
                name    = "Microsoft.Web/serverFarms"
                actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
              }
            }
          }
        }
      }

      cind-claims2 = {
        create                 = true
        location               = "centralindia"
        address_space          = "101.122.96.0/24"
        enable_ddos_protection = false
        dns_servers            = []
        tags                   = { created_by = "terraform" }

        subnet_configs = {
          cind-pvt = {
            create            = true
            address_prefix    = "101.122.96.0/27"
            service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
          }
          cind-aiservice = {
            create         = true
            address_prefix = "101.122.96.48/28"
            delegation = {
              name = "functionapp"
              service_delegation = {
                name    = "Microsoft.Web/serverFarms"
                actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
              }
            }
          }
        }
      }
    }
  }

  nsg_configs = {
    nsg1 = {
      create   = true
      nsg_name = "nsg-infy-test2"
      security_rules = [
        {
          name                       = "Allow-InBound"
          priority                   = 500
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "*"
          destination_address_prefix = "VirtualNetwork"
          source_port_range          = "*"
          destination_port_range     = "443"
        }
      ]
    }

    nsg2 = {
      create   = true
      nsg_name = "nsg-infy-test"
      security_rules = [
        {
          name                       = "Allow-InBound"
          priority                   = 500
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "*"
          destination_address_prefix = "VirtualNetwork"
          source_port_range          = "*"
          destination_port_range     = "443"
        }
      ]
    }

    nsg_existing = {
      create            = false
      existing_nsg_name = "infy-manual-nsg"
    }
  }

  nsg_associations = {
    assoc_pvt = {
      create     = true
      vnet_key   = "cind-claims"
      subnet_key = "cind-pvt"
      nsg_key    = "nsg1"
    }

    assoc_func = {
      create     = true
      vnet_key   = "cind-claims"
      subnet_key = "cind-funtionsapp"
      nsg_key    = "nsg1"
    }

    assoc_cosmos = {
      create     = true
      vnet_key   = "cind-claims"
      subnet_key = "cind-cosmosdb"
      nsg_key    = "nsg2"
    }

    assoc_aiservice = {
      create     = true
      vnet_key   = "cind-claims"
      subnet_key = "cind-aiservice"
      nsg_key    = "nsg_existing"
    }
  }

  # Wrap the inner maps into tomap() so types match the declared
  # `map(map(object(...)))` for `var.virtual_networks`.
  # Effective shapes (locals are authoritative now)
  # Use comprehensions to ensure proper map typing without tomap conversion errors.
  effective_virtual_networks = { for k, v in local.virtual_networks : k => { for ik, iv in v : ik => iv } }
  effective_nsg_configs      = { for k, v in local.nsg_configs : k => v }
  effective_nsg_associations = { for k, v in local.nsg_associations : k => v }

  # Resource group defaults (migrated from env tfvars). Use
  # local.effective_resource_group in place of the old `var.resource_group`.
  resource_group = {
    create   = false
    name     = "madan-test"
    location = "centralindia"
    tags     = {}
  }

  effective_resource_group = local.resource_group
}
