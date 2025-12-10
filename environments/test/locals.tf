locals {
  virtual_networks = {
    vnet003 = {
      location               = "centralindia"
      address_space          = "10.0.0.0/16"
      enable_ddos_protection = false
      dns_servers            = ["168.63.129.16"] #168.63.129.16 is the Azure-provided DNS server
      subnet_configs = {
        # snet-aks = {
        #   address_prefix     = "10.0.0.0/24"
        #   create_nsg         = false
        #   create_route_table = false
        # }
        # snet-apim = {
        #   address_prefix = "10.0.1.0/24"
        #   create_nsg     = false
        # }
        # snet-psql = {
        #   address_prefix    = "10.0.2.0/24"
        #   create_nsg        = false
        #   service_endpoints = ["Microsoft.Storage"]
        #   delegation = {
        #     name = "fs"
        #     service_delegation = {
        #       name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        #       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        #     }
        #   }
        # }
        # snet-st = {
        #   address_prefix     = "10.0.3.0/24"
        #   create_nsg         = true
        #   create_route_table = true
        #   service_endpoints  = ["Microsoft.Storage"]
        # }
        # snet-pass = {
        #   address_prefix     = "10.0.4.0/24"
        #   create_nsg         = true
        #   create_route_table = true
        #   service_endpoints  = ["Microsoft.Storage", "Microsoft.Web"]
        #   delegation = {
        #     name = "functionapp"
        #     service_delegation = {
        #       name    = "Microsoft.Web/serverFarms"
        #       actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        #     }
        #   }
        # }
        snet-kv = {
          address_prefix     = "10.0.5.0/24"
          create_nsg         = false
          create_route_table = false
          service_endpoints  = ["Microsoft.KeyVault"]
        }
        # snet-redis = {
        #   address_prefix = "10.0.6.0/24"
        #   create_nsg     = false
        # }
        # snet-sqlmi = {
        #   vnet_key           = "preprod-vnet"
        #   address_prefix     = "10.0.7.0/24"
        #   create_nsg         = true
        #   create_route_table = true
        #   delegation = {
        #     name = "sqlmi"
        #     service_delegation = {
        #       name    = "Microsoft.Sql/managedInstances"
        #       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
        #     }
        #   }
        # }
        # snet-ml = {
        #   address_prefix    = "10.0.8.0/24"
        #   service_endpoints = ["Microsoft.Storage"]
        # }
        snet-cosmos-mongo = {
          address_prefix    = "10.0.9.0/24"
          service_endpoints = ["Microsoft.AzureCosmosDB"]
        }
        snet-di = {
          address_prefix = "10.0.10.0/24"
        }
      }
    },
    # vnet004 = {
    #   location               = "eastus"
    #   address_space          = "10.1.0.0/16"
    #   enable_ddos_protection = false
    #   dns_servers            = ["168.63.129.16"] #168.63.129.16 is the Azure-provided DNS server
    #   subnet_configs = {
    #     snet-aoai = {
    #       address_prefix    = "10.1.0.0/24"
    #       service_endpoints = ["Microsoft.CognitiveServices"]
    #       create_nsg         = true
    #     }
    #   }
    # }
  }
}

locals {
  storage_accounts = {
    stfile = {
      account_tier                      = "Premium"
      account_replication_type          = "LRS"
      account_kind                      = "FileStorage" # StorageV2 for blob storage
      snet_id                           = var.enable_storage_account ? module.vnet["vnet003"].vnet_id : ""
      vnet_id                           = var.enable_storage_account ? module.vnet["vnet003"].subnet_ids["snet-st"] : ""
      https_traffic_only_enabled        = true
      shared_access_key_enabled         = true
      min_tls_version                   = "TLS1_2"
      enable_blob_versioning            = true
      delete_retention_days             = 7
      infrastructure_encryption_enabled = true
      enable_storage_diagnostics        = false
      private_endpoint_enabled          = false
      subresource_names                 = ["file"] #["blob", "file", "table", "queue"]
      log_categories                    = ["StorageRead", "StorageWrite", "StorageDelete"]
      metric_categories                 = ["AllMetrics", "Transaction", "Capacity"]
      tags = {
        environment = var.env
        created_by  = "terraform"
      }
    }
  }
}

locals {
  #function app configurations
  function_apps = {
    func-win03 = {
      os_type                       = "Windows"
      runtime_stack                 = "v6.0"
      storage_required              = true
      public_network_access_enabled = false
      subnet_id                     = var.enable_function_app ? module.vnet["vnet003"].subnet_ids["snet-pass"] : ""
      vnet_id                       = var.enable_function_app ? module.vnet["vnet003"].vnet_id : ""
      tags = {
        environment = var.env
        created_by  = "terraform"
        app_os      = "windows"
      }
    }
    func-linux03 = {
      os_type                       = "Linux"
      runtime_stack                 = "11"
      storage_required              = true
      public_network_access_enabled = false
      subnet_id                     = var.enable_function_app ? module.vnet["vnet003"].subnet_ids["snet-pass"] : ""
      vnet_id                       = var.enable_function_app ? module.vnet["vnet003"].vnet_id : ""
      tags = {
        environment = var.env
        created_by  = "terraform"
        app_os      = "linux"
      }
    }
  }
}

locals {
  kv_configs = {
    kv003 = {
      sku_name                      = "standard"
      soft_delete_retention_days    = 7
      purge_protection_enabled      = false
      enable_rbac_authorization     = false
      private_endpoint_enabled      = false
      public_network_access_enabled = false
      vnet_id                       = var.enable_kv ? module.vnet["vnet003"].vnet_id : ""
      subnet_id                     = var.enable_kv ? module.vnet["vnet003"].subnet_ids["snet-kv"] : ""
      log_categories                = ["AuditEvent"]
      metric_categories             = ["AllMetrics"]
      tags = {
        created_by = "terraform"
      }
    }
  }
}

locals {
  aks_configs = {
    aks003 = {
      name               = "aks001"
      kubernetes_version = "1.30.8" #az aks get-versions --location centralindia
      private_cluster    = true
      network_plugin     = "azure"
      load_balancer_sku  = "standard"
      os_sku             = "Ubuntu"
      node_os_disk_type  = "Ephemeral"
      encryption_host    = true
      vnet_subnet_id     = var.enable_aks ? module.vnet["vnet003"].subnet_ids["snet-aks"] : ""
      aks_service_cidr   = "10.1.0.0/16"
      aks_dns_service_ip = "10.1.0.10"
      tags = {
        created_by = "terraform"
      }
      default_node_pool = {
        name         = "defaultnp" #must begin with a lowercase letter, contain only lowercase letters and numbers and be between 1 and 12 characters in length,
        vm_size      = "Standard_D2s_v3"
        zones        = ["1"]
        min_count    = 2
        max_count    = 4
        max_pods     = 15
        os_disk_size = 30
      }

      additional_node_pools = {
        np1 = {
          name         = "np1"
          vm_size      = "Standard_D2s_v3"
          min_count    = 2
          max_count    = 4
          max_pods     = 15
          os_disk_size = 30
          zones        = ["1"]
        }
      }
    }
  }
}

locals {
  # PostgreSQL flexible server configurations
  # Each key is the server name, and the value is a map of its properties
  postgresql_servers = {
    postgres003 = {
      psql_administrator_login      = "psqladmin"
      psql_administrator_password   = ""   # Use a secure password in production
      psql_version                  = "15" # PostgreSQL version
      sku_name                      = "GP_Standard_D2s_v3"
      storage_mb                    = 32768      # Storage size in MB for the PostgreSQL flexible server
      zone                          = "1"        # Specify the zone if needed, e.g., "1", "2", or "3"
      high_availability_mode        = "SameZone" # Multi-Zone HA is not supported in Central India region so we default to SameZone
      standby_zone                  = "1"        # Specify the standby zone if needed, e.g., "1", "2", or "3"
      active_directory_auth_enabled = true       # Set to true if you want to enable Active Directory authentication
      vnet_id                       = var.enable_postgresql_flex ? module.vnet["vnet003"].vnet_id : ""
      subnet_id                     = var.enable_postgresql_flex ? module.vnet["vnet003"].subnet_ids["snet-psql"] : ""
      log_categories                = ["PostgreSQLLogs"]
      metric_categories             = ["AllMetrics"]
      tags = {
        environment = var.env
        created_by  = "terraform"
      }
      db_name = ["test_db"]
    }
    # Add more PostgreSQL servers here as needed
  }
}

locals {
  apim_configs = {
    apim3 = {
      publisher_name                = "Infosys"
      subnet_id                     = var.enable_apim ? module.vnet["vnet003"].subnet_ids["snet-apim"] : ""
      publisher_email               = "" #publisher email
      sku_name                      = "Developer_1"
      public_network_access_enabled = true
      tags = {
        created_by = "terraform"
      }
    }
  }
}

# Define your APIs in locals (as you had before)
locals {
  apis = {
    dev-api = {
      user-update = {
        operation_id = "user-update"
        method       = "PUT"
        url_template = "/users/{id}/update"
        template_parameter = [
          {
            name     = "id"
            type     = "number"
            required = true
          }
        ]
      }
    }

    test-api = {
      user-get = {
        operation_id = "user-get"
        method       = "GET"
        url_template = "/users/{id}"
        template_parameter = [
          {
            name     = "id"
            type     = "number"
            required = true
          }
        ]
      },
      user-create = {
        operation_id = "user-create"
        method       = "POST"
        url_template = "/users/create"
      }
    }
  }

  # Transform the APIs to match the module's expected structure
  transformed_apis = {
    for api_name, operations in local.apis : api_name => {
      service_url = "https://${api_name}-example.com/api"
      operations  = operations
    }
  }
}

# Redis cache configurations
locals {
  redis_cache = {
    aks-redis003 = {
      redis_capacity            = 2 # P2 => capacity 2
      redis_family              = "C"
      redis_sku_name            = "Standard"
      redis_minimum_tls_version = "1.2"
      redis_version             = "6"
      subnet_id                 = var.enable_redis_cache ? module.vnet["vnet003"].subnet_ids["snet-redis"] : ""
      vnet_id                   = var.enable_redis_cache ? module.vnet["vnet003"].vnet_id : ""
      enable_redis_diagnostics  = true
      metric_categories         = ["AllMetrics"]

      tags = {
        created_by = "terraform"
      }
    }
  }
}

locals {
  sqlmi_servers = {
    sqlmi001 = {
      sqlmi_db_name                = ["test_db"] # Uncomment if you want to create a database
      administrator_login          = "sqlmiadmin"
      administrator_login_password = ""
      enable_sqlmi_diagnostics     = true
      metric_categories            = ["AllMetrics"]
      subnet_id                    = var.enable_sqlmi ? module.vnet["vnet003"].subnet_ids["snet-sqlmi"] : ""
      network_security_group_name  = var.enable_sqlmi ? module.vnet["vnet003"].nsg_name["snet-sqlmi"] : ""
      tags = {
        created_by = "terraform"
      }
    }
  }
}

locals {
  di_account = {
    documentIntellegence = {
      di_name_prefix = "di"
      sku_name       = "S0"
      kind           = "FormRecognizer"
      vnet_id        = var.enable_di_account ? module.vnet["vnet003"].vnet_id : ""
      snet_id        = var.enable_di_account ? module.vnet["vnet003"].subnet_ids["snet-di"] : ""
    }
  }
}



locals {
  aml_workspace = {
    amlworkspace001 = {
      ml_workspace_nameprefix = "amlworkspace001"
      vnet_id                 = var.enable_aml_workspace ? module.vnet["vnet003"].vnet_id : ""
      subnet_id               = var.enable_aml_workspace ? module.vnet["vnet003"].subnet_ids["snet-ml"] : ""
      key_vault_id            = var.enable_kv ? module.kv["kv003"].kv_id : ""
      storage_account_id      = var.enable_storage_account ? module.storage_account["st003"].storage_account_id : ""
    }
  }
}

locals {
  azure_documentdb = {
    docdb001 = {
      administrator_username = "mongoAdmin"
      administrator_password = ""
      shard_count            = 1
      compute_tier           = "Free"
      high_availability_mode = "Disabled"
      geo_replica_location   = "South India"
      storage_size_in_gb     = 32
      mongodb_version        = "8.0"
    }
  }
}

locals {
  UserAssignedIdenti = {
    functionapp = {
      identity_name = "functionapp"
    }
    cosmos = {
      identity_name = "cosmos"
    }
  }
}