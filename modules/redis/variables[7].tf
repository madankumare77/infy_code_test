variable "redis_name_prefix" {
  description = "Name of the Redis cache instance"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet where the Redis cache will be deployed"
  type        = string

}
variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}
variable "rg_name" {
  description = "The name of the resource group where the Redis cache will be created"
  type        = string
}
variable "redis_version" {
  description = "The version of Redis to use"
  type        = string

}
variable "redis_capacity" {
  description = "The capacity of the Redis cache"
  type        = number
}
variable "redis_family" {
  description = "The family of the Redis cache"
  type        = string
}
variable "redis_sku_name" {
  description = "The SKU name of the Redis cache"
  type        = string
  default     = "Standard"

}
variable "redis_minimum_tls_version" {
  description = "The minimum TLS version for the Redis cache"
  type        = string
  default     = "1.2"

}
variable "vnet_id" {
  description = "The ID of the virtual network where the Redis cache will be linked"
  type        = string
}
variable "enable_redis_diagnostics" {
  description = "Enable diagnostic settings for the Redis cache"
  type        = bool
  default     = true
}
variable "env" {
  description = "The environment for the Redis cache"
  type        = string
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace to send diagnostics to"
  type        = string
  default     = ""
}
variable "log_categories" {
  description = "List of log categories to enable for diagnostics"
  type        = list(string)
  default     = [] # ["AllLogs"] # Default categories, can be customized
}
variable "metric_categories" {
  description = "List of metric categories to enable for diagnostics"
  type        = list(string)
  default     = ["AllMetrics"]
}
variable "tags" {
  description = "A map of tags to assign to the Redis cache"
  type        = map(string)
  default     = {}
}