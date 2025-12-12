terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
       }
  }
}

# Discover current Azure tenant from the authenticated CLI context
data "azurerm_client_config" "current" {}

# Explicitly configure AzureAD provider using the current tenant
provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
