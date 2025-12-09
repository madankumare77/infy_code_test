output "windows_function_app_ids" {
  value = { for k, v in azurerm_windows_function_app.windows : k => v.id }
}

output "linux_function_app_ids" {
  value = { for k, v in azurerm_linux_function_app.linux : k => v.id }
}