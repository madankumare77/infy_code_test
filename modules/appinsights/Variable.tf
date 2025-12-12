variable "env" { type = string }
variable "name_prefix" {
  type = string
}
variable "location" { type = string }
variable "rg_name" { type = string }
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

output "application_insights_id" {
  value = azurerm_application_insights.preprod.id
}