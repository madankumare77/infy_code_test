output "postgres_server_id" {
  value = azurerm_postgresql_flexible_server.this.id
}

output "postgresql_flex_name" {
  value = azurerm_postgresql_flexible_server.this.name

}

output "postgresql_flex_pass" {
  value     = azurerm_postgresql_flexible_server.this.administrator_password
  sensitive = true
}