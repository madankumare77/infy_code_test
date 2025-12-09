resource "azurerm_user_assigned_identity" "preprod" {
  location            = var.location
  name                = "id-${var.env}-${var.identity_name}"
  resource_group_name = var.rg_name
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.preprod.principal_id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.preprod.client_id
}
