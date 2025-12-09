variable "sqlmi_server_name_prefix" {
  type = string
}
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "sqlmi_db_name" {
  type    = list(string)
  default = []
}
variable "short_term_retention_days" {
  type    = number
  default = 7
}
variable "env" {
  description = "The name of the environment"
  type        = string
}
variable "network_security_group_name" {
  description = "The ID of the Network Security Group to associate with the SQL Managed Instance"
  type        = string
  default     = ""
}
variable "tags" {
  description = "A map of tags to assign to the SQL Managed Instance"
  type        = map(string)
  default     = {}
}
variable "enable_sqlmi_diagnostics" {
  description = "Enable diagnostic settings for the SQL Managed Instance"
  type        = bool
  default     = false
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostics"
  type        = string
  default     = ""
}
variable "log_categories" {
  description = "List of log categories to enable for diagnostics"
  type        = list(string)
  default     = []
}
variable "metric_categories" {
  description = "List of metric categories to enable for diagnostics"
  type        = list(string)
  default     = ["AllMetrics"]
}
variable "administrator_login" {
  type = string
}
variable "administrator_login_password" {
  type = string
}