# resource "azurerm_cognitive_account" "preprod" {
#   name                = "${var.env}-OpenAI"
#   location            = var.location
#   resource_group_name = var.rg_name

#   kind     = var.kind     #"AIServices"      # as per your input
#   sku_name = var.sku_name #"S0"

#   public_network_access_enabled = false
# }

# ---------------------------------------------------------
# Azure OpenAI (Cognitive Account) — public disabled
# ---------------------------------------------------------
resource "azurerm_cognitive_account" "preprod" {
  name                = "${var.name_prefix}"
  location            = var.location
  resource_group_name = var.rg_name

  kind                  = var.kind
  sku_name              = var.sku_name
  custom_subdomain_name = var.custom_subdomain

  # Block all public access — only Private Endpoints will work
  public_network_access_enabled = false

  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [var.UserAssigned_identity]
  # }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
    }
  )
}

# ---------------------------------------------------------
# Private DNS zone for AOAI (resolves public hostname -> PE IP inside VNet)
# ---------------------------------------------------------
resource "azurerm_private_dns_zone" "openai" {
  name                = var.private_dns_zone_name # privatelink.openai.azure.com
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_link" {
  name                  = "${azurerm_private_dns_zone.openai.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  resource_group_name   = var.rg_name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# ---------------------------------------------------------
# Private Endpoint to AOAI (subresource 'account')
# ---------------------------------------------------------
resource "azurerm_private_endpoint" "openai" {
  name                = "pvt-endpoint-${azurerm_cognitive_account.preprod.name}"
  location            = var.pe_location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${azurerm_cognitive_account.preprod.name}-pe-conn"
    private_connection_resource_id = azurerm_cognitive_account.preprod.id
    subresource_names              = ["account"] # AOAI / Cognitive Services PE group
    is_manual_connection           = false       # auto-approve when same subscription/tenant
  }

  # Bind the PE to the Private DNS zone for AOAI
  private_dns_zone_group {
    name                 = "openai-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }
}

# ---------------------------------------------------------
# One or more AOAI model deployments
# ---------------------------------------------------------
# resource "azurerm_cognitive_deployment" "openai_deployments" {
#   for_each             = { for d in var.deployments : d.name => d }
#   name                 = each.key
#   cognitive_account_id = azurerm_cognitive_account.preprod.id

#   model {
#     format  = "OpenAI"
#     name    = each.value.model.name
#     version = each.value.model.version
#   }

#   sku {
#     name = "Standard"
#   }
# }

variable "custom_subdomain" {
  description = "Custom subdomain name for the Cognitive Account"
  type        = string
}
variable "private_dns_zone_name" {
  description = "The name of the private DNS zone for Azure OpenAI"
  type        = string
}
variable "vnet_id" {
  description = "The ID of the virtual network to which the Azure OpenAI private endpoint will be associated"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet to which the Azure OpenAI private endpoint will be associated"
  type        = string
}


# variable "deployments" {
#   description = "List of Azure OpenAI model deployments"
#   type = list(object({
#     name = string
#     model = object({
#       name    = string
#       version = string
#     })
#   }))
#   # default = [
#   #   {
#   #     name = "gpt-4-deployment"
#   #     model = {
#   #       name    = "gpt-4.1"
#   #       version = "2025-04-14"
#   #     }
#   #   },
#     # {
#     #   name = "gpt-4o-deployment"
#     #   model = {
#     #     name    = "gpt-4o"
#     #     version = "2024-05-15"
#     #   }
#     # }
#   #]

# }
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "pe_location" {
  type = string
}
variable "log_analytics_workspace_id" {
  type = string
}
 
 
data "azurerm_monitor_diagnostic_categories" "cog_cats" {
  resource_id = azurerm_cognitive_account.preprod.id
}
 
resource "azurerm_monitor_diagnostic_setting" "openai_diag" {
  name                           = "aoai-diag-to-law"
  target_resource_id             = azurerm_cognitive_account.preprod.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"
 
  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.cog_cats.log_category_types
    content {
      category = enabled_log.value
    }
  }
 
  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.cog_cats.metrics
    content {
      category = enabled_metric.value
    }
  }
}