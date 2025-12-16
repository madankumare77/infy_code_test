#nsg
# Create NSG when create_nsg = true
resource "azurerm_network_security_group" "nsg" {
  count               = var.create_nsg ? 1 : 0
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.rg_name
  # add security rules here when needed
}

# Use existing NSG when create_nsg = false
data "azurerm_network_security_group" "existing_nsg" {
  count               = var.create_nsg ? 0 : 1
  name                = var.nsg_name
  resource_group_name = var.rg_name
}


# Resolve the NSG name safely regardless of the branch
locals {
  nsg_name_resolved = var.create_nsg ? azurerm_network_security_group.nsg[0].name : data.azurerm_network_security_group.existing_nsg[0].name
}

# One resource per rule
resource "azurerm_network_security_rule" "managed" {
  for_each = { for r in var.security_rules : r.name => r }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol

  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range

  resource_group_name         = var.rg_name
  network_security_group_name = local.nsg_name_resolved
}


# Rules schema (common fields). Extend if you need ranges/prefixes lists.
variable "security_rules" {
  description = "List of NSG rules to manage for this NSG."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string          # "Inbound" or "Outbound"
    access                     = string          # "Allow" or "Deny"
    protocol                   = string          # "Tcp" | "Udp" | "*" | "Ah" | "Esp"
    source_address_prefix      = string
    destination_address_prefix = string
    source_port_range          = string          # "*" or single port
    destination_port_range     = string          # "*" or single port
  }))
  default = []
}



# Toggle: create NSG vs. consume existing
variable "create_nsg" {
  description = "If true, create a default NSG; if false, use an existing NSG by name."
  type        = bool
  default     = true
}

variable "nsg_name" {
  description = "The name of the Network Security Group to create."
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group where the NSG will be created or exists."
  type        = string
}
variable "location" {
  description = "The Azure region where the NSG will be created."
  type        = string
}

output "nsg_id" {
  value = var.create_nsg ? azurerm_network_security_group.nsg[0].id : data.azurerm_network_security_group.existing_nsg[0].id
}


output "rule_names" {
  value = keys(azurerm_network_security_rule.managed)
}
