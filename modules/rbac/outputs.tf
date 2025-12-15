output "id" {
  value       = azurerm_role_assignment.this.id
  description = "The Role Assignment ID."
}

output "name" {
  value       = azurerm_role_assignment.this.name
  description = "The Role Assignment Name."
}

output "principal_type" {
  value       = azurerm_role_assignment.this.principal_type
  description = "The `principal_id`'s type: e.g. `User`, `Group`, `Service Principal`, `Application`, `etc`."
}

output "scope" {
  value       = azurerm_role_assignment.this.scope
  description = "List the scope on which rbac is applied"
}

output "principal_id" {
  value       = azurerm_role_assignment.this.principal_id
  description = "The object ID of the role assigned"
}

output "resource" {
  value       = azurerm_role_assignment.this
  description = "The Role Assignment resource."
}