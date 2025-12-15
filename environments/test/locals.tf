# Virtual network configuration with subnets for claims application infrastructure
locals {
  virtual_networks = {
    cind-claims = {
      location               = "centralindia"
      address_space          = "100.122.96.0/24"
      enable_ddos_protection = false
      dns_servers            = ["168.63.129.16"] #168.63.129.16 is the Azure-provided DNS server
      tags = {
        created_by = "terraform"
      }
      subnet_configs = {
        cind-pvt = {
          address_prefix    = "100.122.96.0/27"
          service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
          nsg_id            = module.nsg["nsg1"].nsg_id
        }
        cind-cosmosdb = {
          address_prefix    = "100.122.96.32/28"
          service_endpoints = ["Microsoft.AzureCosmosDB"]
        }
        cind-aiservice = {
          address_prefix = "100.122.96.48/28"
          #service_endpoints = [""]
        }
        cind-funtionsapp = {
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
        # snet-kv = {
        #   address_prefix     = "10.0.5.0/24"
        #   create_nsg         = true
        #   create_route_table = true
        #   service_endpoints  = ["Microsoft.KeyVault"]
        # }
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
        # snet-cosmos-mongo = {
        #   address_prefix    = "10.0.9.0/24"
        #   service_endpoints = ["Microsoft.AzureCosmosDB"]
        # }
        # snet-di = {
        #   address_prefix = "10.0.10.0/24"
        # }
      }
    }
  }
}

# Storage account configuration for function app data and blob storage
locals {
  storage_accounts = {
    stcindclaims = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2" # StorageV2 for blob storage,, FileStorage for file storage
      access_tier              = "Hot"
      # Correct mapping: subnet id for snet_id, VNet id for vnet_id
      snet_id                           = var.enable_storage_account ? module.vnet["cind-claims"].subnet_ids["cind-pvt"] : ""
      vnet_id                           = var.enable_storage_account ? module.vnet["cind-claims"].vnet_id : ""
      https_traffic_only_enabled        = true
      shared_access_key_enabled         = false
      min_tls_version                   = "TLS1_2"
      enable_blob_versioning            = true # Please review before enable due to cost implications
      delete_retention_days             = 7
      infrastructure_encryption_enabled = true
      enable_immutability_policy        = true
      immutability_period_days          = 30
      immutability_policy_state         = "Unlocked"
      enable_container_delete_retention = true
      container_delete_retention_days   = 7
      allow_nested_items_to_be_public   = false
      #prevent_storage_account_deletion  = true
      enable_storage_diagnostics = true
      private_endpoint_enabled   = true
      subresource_names          = ["blob"] #["blob", "file", "table", "queue"]
      log_categories             = ["StorageRead", "StorageWrite", "StorageDelete"]
      metric_categories          = ["Transaction"]
      tags = {
        environment          = var.env
        created_by           = "terraform"
        INFY_EA_WorkLoadType = "test"
        "INFY_EA_BusinessUnit" : "IS",
        "INFY_EA_CustomTag03" : "EPMProjects",
        "INFY_EA_CustomTag01" : "No PO",
        "INFY_EA_WorkLoadType" : "Test",
        "INFY_EA_Workinghours" : "NA",
        "INFY_EA_CustomTag04" : "PaaS",
        "INFY_EA_CostCenter" : "No FR_IS",
        "INFY_EA_Role" : "Function App",
        "INFY_EA_ResourceName" : "func-claims-test ",
        "INFY_EA_Automation" : "Yes",
        "INFY_EA_Purpose" : "IS Internal",
        "INFY_EA_Technical_Tags" : "EPM_CFG@infosys.com",
        "INFY_EA_ProjectCode" : "EPMPRJBE",
        "INFY_EA_Weekendshutdown" : "No",
        "INFY_EA_CustomTag02" : "Infosys Limited"
      }
    }
  }
}

# Azure Function Apps configuration for serverless compute workloads
locals {
  function_apps = {
    # func-claims-orchestration-test = {
    #   os_type                       = "Windows"
    #   runtime_stack                 = "v6.0"
    #   public_network_access_enabled = false
    #   subnet_id                     = var.enable_function_app ? module.vnet["cind-claims"].subnet_ids[""] : ""
    #   vnet_id                       = var.enable_function_app ? module.vnet["cind-claims"].vnet_id : ""
    #   tags = {
    #     environment = var.env
    #     created_by  = "terraform"
    #     app_os      = "windows"
    #   }
    # }
    func-claims-test = {
      os_type                       = "Linux"
      runtime_stack                 = "21"
      public_network_access_enabled = false
      subnet_id                     = var.enable_function_app ? module.vnet["cind-claims"].subnet_ids["cind-funtionsapp"] : ""
      vnet_id                       = var.enable_function_app ? module.vnet["cind-claims"].vnet_id : ""
      storage_account_name          = var.enable_storage_account ? module.storage_account["stcindclaims"].storage_account_name : ""
      tags = {
        created_by = "terraform"
        app_os     = "linux"
        "INFY_EA_BusinessUnit" : "IS",
        "INFY_EA_CustomTag03" : "EPMProjects",
        "INFY_EA_CustomTag01" : "No PO",
        "INFY_EA_WorkLoadType" : "Test",
        "INFY_EA_Workinghours" : "NA",
        "INFY_EA_CustomTag04" : "PaaS",
        "INFY_EA_CostCenter" : "No FR_IS",
        "INFY_EA_Role" : "Function App",
        "INFY_EA_ResourceName" : "func-claims-test ",
        "INFY_EA_Automation" : "Yes",
        "INFY_EA_Purpose" : "IS Internal",
        "INFY_EA_Technical_Tags" : "EPM_CFG@infosys.com",
        "INFY_EA_ProjectCode" : "EPMPRJBE",
        "INFY_EA_Weekendshutdown" : "No",
        "INFY_EA_CustomTag02" : "Infosys Limited"
      }
    }
  }
}

# Azure Key Vault configurations for secure storage of secrets and certificates
locals {
  kv_configs = {
    kv005-cind-claims = {
      sku_name                        = "standard"
      soft_delete_retention_days      = 90
      purge_protection_enabled        = true
      enable_rbac_authorization       = true
      private_endpoint_enabled        = true
      public_network_access_enabled   = false
      vnet_id                         = var.enable_kv ? module.vnet["cind-claims"].vnet_id : ""
      subnet_id                       = var.enable_kv ? module.vnet["cind-claims"].subnet_ids["cind-pvt"] : ""
      enable_kv_diagnostics           = true
      log_categories                  = ["AuditEvent"]
      metric_categories               = ["AllMetrics"]
      use_existing_private_dns_zone   = false
      create_private_dns_link         = true
      enabled_for_deployment          = true
      enable_for_disk_encryption      = true
      enabled_for_template_deployment = true
      #prevent_kv_deletion             = true
      tags = {
        created_by  = "terraform"
        criticality = "high"
        "INFY_EA_CustomTag01" : "No Po"
        "INFY_EA_CustomTag02" : "Infosys Limited"
        "INFY_EA_CustomTag03" : "EPMCFG"
        "INFY_EA_CustomTag04" : "PaaS"
        "INFY_EA_BusinessUnit" : "IS"
        "INFY_EA_Automation" : "No"
        "INFY_EA_CostCenter" : "No FR_IS"
        "INFY_EA_Technical_Tag" : "EPM_CFG@infosys.com"
        "INFY_EA_Role" : "key vault"
        "INFY_EA_ProjectCode" : "EPMPRJBE"
        "INFY_EA_Purpose" : "IS Internal"
        "INFY_EA_Weekendshutdown" : "No"
        "INFY_EA_Workinghours" : "00:00 23:59",
        "INFY_EA_WorkLoadType" : "Test"
      }
    }
  }
}

# Azure Kubernetes Service (AKS) cluster configuration with node pools
locals {
  aks_configs = {
    aks003 = {
      name                = "aks001"
      kubernetes_version  = "1.30.8" #az aks get-versions --location centralindia
      private_cluster     = true
      network_plugin      = "azure"
      load_balancer_sku   = "standard"
      os_sku              = "Ubuntu"
      node_os_disk_type   = "Ephemeral"
      encryption_host     = true
      network_data_plane  = "cilium"
      network_plugin_mode = "overlay"
      vnet_subnet_id      = var.enable_aks ? module.vnet["cind-claims"].subnet_ids["snet-aks"] : ""
      aks_service_cidr    = "10.1.0.0/16"
      aks_dns_service_ip  = "10.1.0.10"
      tags = {
        created_by  = "terraform"
        criticality = "medium"
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

# PostgreSQL flexible server configurations for relational database workloads
locals {
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
      vnet_id                       = var.enable_postgresql_flex ? module.vnet["cind-claims"].vnet_id : ""
      subnet_id                     = var.enable_postgresql_flex ? module.vnet["cind-claims"].subnet_ids["snet-psql"] : ""
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

# API Management service configuration for API gateway and management
locals {
  apim_configs = {
    apim3 = {
      publisher_name                = "Infosys"
      subnet_id                     = var.enable_apim ? module.vnet["cind-claims"].subnet_ids["snet-apim"] : ""
      publisher_email               = "" #publisher email
      sku_name                      = "Developer_1"
      public_network_access_enabled = true
      tags = {
        created_by = "terraform"
      }
    }
  }
}

# API definitions with operations and endpoints for APIM
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

  # Transform API configurations into format expected by the APIM module
  transformed_apis = {
    for api_name, operations in local.apis : api_name => {
      service_url = "https://${api_name}-example.com/api"
      operations  = operations
    }
  }
}

# Redis cache configuration for distributed caching and session management
locals {
  redis_cache = {
    aks-redis003 = {
      redis_capacity            = 2 # P2 => capacity 2
      redis_family              = "C"
      redis_sku_name            = "Standard"
      redis_minimum_tls_version = "1.2"
      redis_version             = "6"
      private_endpoint_enabled  = true
      subnet_id                 = var.enable_redis_cache ? module.vnet["cind-claims"].subnet_ids["snet-redis"] : ""
      vnet_id                   = var.enable_redis_cache ? module.vnet["cind-claims"].vnet_id : ""
      enable_redis_diagnostics  = true
      metric_categories         = ["AllMetrics"]

      tags = {
        created_by = "terraform"
      }
    }
  }
}

# SQL Managed Instance configuration for enterprise SQL Server workloads
locals {
  sqlmi_servers = {
    sqlmi001 = {
      sqlmi_db_name                = ["test_db"] # Uncomment if you want to create a database
      administrator_login          = "sqlmiadmin"
      administrator_login_password = ""
      enable_sqlmi_diagnostics     = true
      short_term_retention_days    = 35
      metric_categories            = ["AllMetrics"]
      subnet_id                    = var.enable_sqlmi ? module.vnet["cind-claims"].subnet_ids["snet-sqlmi"] : ""
      network_security_group_name  = var.enable_sqlmi ? module.vnet["cind-claims"].nsg_name["snet-sqlmi"] : ""
      tags = {
        created_by = "terraform"
      }
    }
  }
}

# Azure Document Intelligence (Form Recognizer) configuration for document processing
locals {
  di_account = {
    documentIntellegence = {
      di_name_prefix           = "di-claims-test-poc"
      sku_name                 = "S0"
      kind                     = "FormRecognizer"
      private_endpoint_enabled = false
      vnet_id                  = var.enable_di_account ? module.vnet["cind-claims"].vnet_id : ""
      snet_id                  = var.enable_di_account ? module.vnet["cind-claims"].subnet_ids["cind-aiservice"] : ""
      custom_subdomain_name    = "di-claims-test-poc"
      tags = {
        created_by = "terraform"
        "INFY_EA_BusinessUnit" : "IS"
        "INFY_EA_CustomTag03" : "EPMCLOUD"
        "INFY_EA_CustomTag01" : "No PO"
        "INFY_EA_WorkLoadType" : "test"
        "INFY_EA_Workinghours" : "00: 00 23:69"
        "INFY_EA_CustomTag04" : "PaaS"
        "INFY_EA_CostCenter" : "No FR_IS"
        "INFY_EA_Role" : "Document intelligence"
        "INFY_EA_ResourceName" : "di-claims-test-poc"
        "INFY_EA_Automation" : "No"
        "INFY_EA_Purpose" : "IS Internal"
        "INFY_EA_Technical_Tags" : "EPM_Cloud@infosys.com"
        "INFY_EA_Weekendshutdown" : "No"
        "INFY_EA_ProjectCode" : "EPMPRJBE"
        "INFY_EA_CustomTag02" : "Infosys Limited"
      }
    }
  }
}

# Azure Machine Learning workspace configuration for ML model training and deployment
locals {
  aml_workspace = {
    mlw-claims-test = {
      ml_workspace_nameprefix  = "mlw01-claims-test"
      private_endpoint_enabled = true
      vnet_id                  = var.enable_aml_workspace ? module.vnet["cind-claims"].vnet_id : ""
      subnet_id                = var.enable_aml_workspace ? module.vnet["cind-claims"].subnet_ids["cind-aiservice"] : ""
      key_vault_id             = var.enable_kv ? module.kv["kv005-cind-claims"].kv_id : ""
      storage_account_id       = var.enable_storage_account ? module.storage_account["stcindclaims"].storage_account_id : ""
      tags = {
        created_by = "terraform"
        "INFY_EA_BusinessUnit" : "IS"
        "INFY_EA_CustomTag03" : "EPMCLOUD"
        "INFY_EA_CustomTag01" : "No PO"
        "INFY_EA_WorkLoadType" : "test"
        "INFY_EA_Workinghours" : "00: 00 23:69"
        "INFY_EA_CustomTag04" : "PaaS"
        "INFY_EA_CostCenter" : "No FR_IS"
        "INFY_EA_Role" : "Machine Learning"
        "INFY_EA_ResourceName" : "mlw-claims-test"
        "INFY_EA_Automation" : "No"
        "INFY_EA_Purpose" : "IS Internal"
        "INFY_EA_Technical_Tags" : "EPM_Cloud@infosys.com"
        "INFY_EA_Weekendshutdown" : "No"
        "INFY_EA_ProjectCode" : "EPMPRJBE"
        "INFY_EA_CustomTag02" : "Infosys Limited"
      }
    }
  }
}

# Azure Cosmos DB for MongoDB vCore cluster configuration
locals {
  azure_documentdb = {
    docdb001 = {
      administrator_username   = "mongoAdmin"
      administrator_password   = ""
      shard_count              = 1
      compute_tier             = "Free"
      high_availability_mode   = "Disabled"
      geo_replica_location     = "South India"
      storage_size_in_gb       = 32
      mongodb_version          = "8.0"
      private_endpoint_enabled = true
      vnet_id                  = var.enable_azure_documentdb ? module.vnet["cind-claims"].vnet_id : ""
      subnet_id                = var.enable_azure_documentdb ? module.vnet["cind-claims"].subnet_ids["snet-cosmos-mongo"] : ""
      tags = {
        created_by = "terraform"
      }
    }
  }
}

# User-assigned managed identities for Azure resource authentication
locals {
  UserAssignedIdenti = {
    functionapp = {
      identity_name = "mannaged_identity_func-claims-test"
      tags = {
        created_by = "terraform"
      }
    }
    cosmos = {
      identity_name = "mannaged_identity_cosdb-cind-claims-test"
      tags = {
        created_by = "terraform"
      }
    }
  }
}

# Azure OpenAI service configuration for AI/ML model deployment
locals {
  azure_openai = {
    is-cind-oai-claims-test12 = {
      location                 = "South India" #Central India not supported for openAI
      sku_name                 = "S0"
      kind                     = "OpenAI"
      private_endpoint_enabled = true
      subnet_id                = var.enable_azure_openai ? module.vnet["cind-claims"].subnet_ids["cind-aiservice"] : ""
      vnet_id                  = var.enable_azure_openai ? module.vnet["cind-claims"].vnet_id : ""
      custom_subdomain         = "is-cind-oai-claims-test12"
      tags = {
        "INFY_EA_BusinessUnit" : "IS"
        "INFY_EA_CustomTag03" : "EPMCLOUD"
        "INFY_EA_CustomTag01" : "No PO"
        "INFY_EA_WorkLoadType" : "test"
        "INFY_EA_Workinghours" : "00: 00 23:69"
        "INFY_EA_CustomTag04" : "PaaS"
        "INFY_EA_CostCenter" : "No FR_IS"
        "INFY_EA_Role" : "OpenAI service"
        "INFY_EA_ResourceName" : "is-sind-oai-test01"
        "INFY_EA_Automation" : "No"
        "INFY_EA_Purpose" : "IS Internal"
        "INFY_EA_Technical_Tags" : "EPM_Cloud@infosys.com"
        "INFY_EA_Weekendshutdown" : "No"
        "INFY_EA_ProjectCode" : "EPMPRJBE"
        "INFY_EA_CustomTag02" : "Infosys Limited"
      }
    }
  }
}

locals {
  cosmos_configs = {
    "cosdb01-cind-claims-test" = {
      cosmos_kind              = "MongoDB"
      offer_type               = "Standard"
      geo_location1            = "SouthIndia"
      private_endpoint_enabled = true
      vnet_id                  = module.vnet["cind-claims"].vnet_id
      subnet_id                = module.vnet["cind-claims"].subnet_ids["cind-cosmosdb"]
      #UserAssigned_identity = module.azure_identity["cosmos"].user_assigned_id
      UserAssigned_identity = module.azure_identity["cosmos"].user_assigned_id
      tags = {
        "INFY_EA_Weekendshutdown" : "No"
        "INFY_EA_Technical_Tags" : "satish.kongara@infosys.com"
        "INFY_EA_BusinessUnit" : "is"
        "INFY_EA_WorkLoadType" : "Test"
        "INFY_EA_ResourceName" : "cosdb-cind-commstation-test"
        "INFY_EA_Workinghours" : "00:00 23:59"
        "INFY_EA_CustomTag02" : "infosys Limited"
        "INFY_EA_CustomTag01" : "no PO"
        "INFY_EA_ProjectCode" : "EPMDB"
        "INFY_EA_CustomTag03" : "EPMDB"
        "INFY_EA_CustomTag04" : "paaS"
        "INFY_EA_CostCenter" : "no FR_IS"
        "INFY_EA_Automation" : "yes"
        "INFY_EA_Purpose" : "IS Internal"
        "INFY_EA_Role" : "DB Server"
      }
    }
  }
}

locals {
  nsg_configs = {
    nsg1 = {
      create_nsg = true
      nsg_name   = "nsg-infy-test"
      location   = data.azurerm_resource_group.rg.location
      rg_name    = data.azurerm_resource_group.rg.name
    }
  }
}

locals {
  private_dns_zones = {
    kv = {
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    openai = {
      private_dns_zone_name = "privatelink.openai.azure.com"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    cosmosdb = {
      private_dns_zone_name = "privatelink.mongo.cosmos.azure.com"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    aml = {
      private_dns_zone_name = "privatelink.azureml.ms"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    di = {
      private_dns_zone_name = "privatelink.cognitiveservices.azure.com"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    storage = {
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
    postgresql = {
      private_dns_zone_name = "privatelink.postgres.database.azure.com"
      vnet_id               = module.vnet["cind-claims"].vnet_id
    }
  }
}