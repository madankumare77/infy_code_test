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
  # subscription_id = "a0b36c09-679f-4dfb-829f-3b6685282dae"
  # tenant_id = "16b3c013-d300-468d-ac64-7eda0820b6d3"
}

# Discover current Azure tenant from the authenticated CLI context
data "azurerm_client_config" "current" {}

# Explicitly configure AzureAD provider using the current tenant
provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
