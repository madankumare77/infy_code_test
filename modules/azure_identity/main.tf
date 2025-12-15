resource "azurerm_user_assigned_identity" "preprod" {
  location            = var.location
  name                = var.identity_name
  resource_group_name = var.rg_name
  tags = merge(
    var.tags,
    {
      "IdentityType" : "UserAssigned"
    }
  )
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.preprod.principal_id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.preprod.client_id
}

output "user_assigned_id" {
  value = azurerm_user_assigned_identity.preprod.id
}
