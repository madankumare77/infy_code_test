
# subscription_id = "00000000-0000-0000-0000-000000000000"
# tenant_id       = "00000000-0000-0000-0000-000000000000"

enabled       = true
allow_destroy = false

resource_group = {
  create   = false
  name     = "rg-infy-prod"
  location = "centralindia"
  tags = {
    created_by  = "terraform"
    environment = "prod"
    owner       = "network-team"
  }
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
          enabled         = true
          address_prefix  = "100.122.96.0/27"
          service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
        }

        cind-cosmosdb = {
          enabled         = true
          address_prefix  = "100.122.96.32/28"
          service_endpoints = ["Microsoft.AzureCosmosDB"]
        }
      }
    }
  }
}

# Import an existing NSG and attach to whichever subnet you want
nsg_configs = {
  nsg_manual = {
    enabled          = true
    create_nsg       = false
    nsg_name         = "nsg-infy-manual"
    existing_rg_name = "rg-infy-prod"
    existing_nsg_name = "nsg-infy-manual"
  }
}

nsg_associations = {
  assoc_pvt = {
    enabled    = true
    vnet_key   = "cind-claims"
    subnet_key = "cind-pvt"
    nsg_key    = "nsg_manual"
  }
}
