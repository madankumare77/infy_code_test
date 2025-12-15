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
