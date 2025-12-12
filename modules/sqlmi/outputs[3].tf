output "sqlmi_id" {
  value = azurerm_mssql_managed_instance.this.id
}
# output "sqlmi_admin_password" {
#   value     = random_password.sqlmi_admin.result
#   sensitive = true
# }