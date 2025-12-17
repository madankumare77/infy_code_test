# Example: create two VNets and two NSGs, then attach NSGs to subnets

enabled       = true
allow_destroy = false

resource_group = {
  create   = false
  name     = "madan-test"
  location = "centralindia"
}

virtual_networks = {
  vnet_group1 = {
    vnet-a = {
      enabled       = true
      location      = "centralindia"
      address_space = "10.0.0.0/16"
      dns_servers   = []
      tags          = { created_by = "example" }

      subnet_configs = {
        subnet-a = {
          enabled        = true
          address_prefix = "10.0.1.0/24"
        }
        subnet-b = {
          enabled        = true
          address_prefix = "10.0.2.0/24"
        }
      }
    }

    vnet-b = {
      enabled       = true
      location      = "centralindia"
      address_space = "10.1.0.0/16"
      dns_servers   = []
      tags          = { created_by = "example" }

      subnet_configs = {
        subnet-c = {
          enabled        = true
          address_prefix = "10.1.1.0/24"
        }
      }
    }
  }
}

nsg_configs = {
  nsg_alpha = {
    enabled    = true
    create_nsg = true
    nsg_name   = "nsg-alpha"
    security_rules = [
      {
        name                       = "Allow-HTTPS"
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

  nsg_beta = {
    enabled    = true
    create_nsg = true
    nsg_name   = "nsg-beta"
  }
}

# Attach NSGs via explicit associations (map keys must match the keys above)
nsg_associations = {
  assoc_a = {
    enabled    = true
    vnet_key   = "vnet-a" # vnet name (not the group key)
    subnet_key = "subnet-a"
    nsg_key    = "nsg_alpha"
  }

  assoc_b = {
    enabled    = true
    vnet_key   = "vnet-a"
    subnet_key = "subnet-b"
    nsg_key    = "nsg_beta"
  }

  assoc_c = {
    enabled    = true
    vnet_key   = "vnet-b"
    subnet_key = "subnet-c"
    nsg_key    = "nsg_alpha"
  }
}
