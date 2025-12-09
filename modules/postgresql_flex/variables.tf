variable "psql_server_name_prefix" {
  type        = string
  description = "Name of the PostgreSQL flexible server."
}
variable "location" {
  type        = string
  description = "The Azure region where the PostgreSQL flexible server will be created."
}
variable "rg_name" {
  type        = string
  description = "The name of the resource group where the PostgreSQL flexible server will be created."
}
variable "env" {
  type        = string
  description = "The name of the environment"
}
variable "sku_name" {
  default     = "GP_Standard_D2s_v3"
  description = "SKU name for the PostgreSQL flexible server"
}
variable "storage_mb" {
  default     = 32768
  description = "Storage size in MB for the PostgreSQL flexible server"
}
variable "psql_version" {
  default     = "15"
  description = "Version of the PostgreSQL flexible server"
  type        = string
}
variable "zone" {
  description = "Availability zone for the PostgreSQL flexible server"
  type        = string
  default     = "1"
}
variable "subnet_id" {
  description = "Subnet ID for the PostgreSQL flexible server"
  type        = string
}
variable "vnet_id" {
  description = "Virtual network ID for the PostgreSQL flexible server"
  type        = string

}
variable "backup_retention_days" {
  description = "Number of days to retain backups for the PostgreSQL flexible server"
  type        = number
  default     = 7
}
variable "password_auth_enabled" {
  description = "Enable password authentication for the PostgreSQL flexible server"
  type        = bool
  default     = true
}
variable "active_directory_auth_enabled" {
  description = "Enable Active Directory authentication for the PostgreSQL flexible server"
  type        = bool
  default     = false
}
variable "public_network_access_enabled" {
  description = "Enable public network access for the PostgreSQL flexible server"
  type        = bool
  default     = false
}
variable "high_availability_mode" {
  description = "High availability mode for the PostgreSQL flexible server"
  type        = string
  default     = "SameZone"
  #Multi-Zone HA is not supported in this region so we default to SameZone
}
variable "standby_zone" {
  description = "Availability zone for the standby server in high availability mode"
  type        = string
  default     = "1"
}
variable "psql_administrator_login" {
  description = "The administrator login for the PostgreSQL flexible server"
  type        = string
}
variable "psql_administrator_password" {
  description = "The administrator password for the PostgreSQL flexible server"
  type        = string
  sensitive   = true
}
variable "private_endpoint_enabled" {
  description = "Enable private endpoint for the PostgreSQL flexible server"
  type        = bool
  default     = false
}
variable "db_name" {
  type    = list(string)
  default = []
}
variable "charset" {
  description = "Character set for the PostgreSQL flexible server database"
  type        = string
  default     = "UTF8"
}
variable "collation" {
  description = "Collation for the PostgreSQL flexible server database"
  type        = string
  default     = "en_US.utf8"
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace to which logs will be sent."
  type        = string
  default     = null
  nullable    = true
}
variable "log_categories" {
  description = "List of log categories to enable for the PostgreSQL flexible server diagnostic settings"
  type        = list(string)
  default     = ["PostgreSQLLogs"]
}
variable "metric_categories" {
  description = "List of metric categories to enable for the PostgreSQL flexible server diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"]
}
variable "tags" {
  description = "Tags to apply to the PostgreSQL flexible server"
  type        = map(string)
  default     = {}
}