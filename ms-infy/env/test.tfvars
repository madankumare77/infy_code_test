
# subscription_id = "00000000-0000-0000-0000-000000000000"
# tenant_id       = "00000000-0000-0000-0000-000000000000"

enabled       = true
allow_destroy = false

resource_group = {
  create   = false
  name     = "madan-test"
  location = "centralindia"
  # tags = {
  #   created_by  = "terraform"
  #   environment = "test"
  # }
}

virtual_networks = {
  vnet1 = {
    cind-claims = {
      enabled                = true
      location               = "centralindia"
      address_space          = "100.122.96.0/24"
      enable_ddos_protection = false
      dns_servers            = ["168.63.129.16"]
      tags = {
        created_by = "terraform"
      }

      subnet_configs = {
        cind-pvt = {
          enabled           = true
          address_prefix    = "100.122.96.0/27"
          service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
        }

        cind-cosmosdb = {
          enabled           = true
          address_prefix    = "100.122.96.32/28"
          service_endpoints = ["Microsoft.AzureCosmosDB"]
        }

        cind-aiservice = {
          enabled        = true
          address_prefix = "100.122.96.48/28"
        }

        cind-funtionsapp = {
          enabled           = true
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
  }
}

# FIX: keys must be unique. Use nsg_created and nsg_existing, not duplicate nsg1.
nsg_configs = {
  nsg_created = {
    enabled    = true
    create_nsg = true
    nsg_name   = "nsg-infy-test"
    #location    = "centralindia"
    #rg_name     = "madan-test"
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
    enabled         = true
    create_nsg      = false
    existing_nsg_name = "infy-manual-nsg"     # or existing_nsg_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/networkSecurityGroups/infy-manual-nsg"
    #existing_rg_name  = "madan-test"          # set if NSG is in a different RG than the VNet
  }
}

# Attach NSG to any subnets you want (flexible)
nsg_associations = {
  assoc_pvt = {
    enabled    = true
    vnet_key   = "cind-claims"
    subnet_key = "cind-pvt"
    nsg_key    = "nsg_created"
  }

  assoc_func = {
    enabled    = true
    vnet_key   = "cind-claims"
    subnet_key = "cind-funtionsapp"
    nsg_key    = "nsg_created"
  }

  assoc_aiservice = {
    enabled    = true
    vnet_key   = "cind-claims"
    subnet_key = "cind-aiservice"
    nsg_key    = "nsg_existing"
  }
}