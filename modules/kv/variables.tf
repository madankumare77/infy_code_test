variable "name_prefix" {
  description = "The name prefix for the Key Vault"
  type        = string

}
variable "rg_name" {
  description = "The name of the resource group where the Key Vault will be created"
  type        = string

}
variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "env" {
  description = "The name of the environment"
  type        = string
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault"
  type        = bool
  default     = true

}
variable "soft_delete_retention_days" {
  description = "The number of days to retain soft-deleted Key Vaults"
  type        = number
  default     = 7
}
variable "sku_name" {
  description = "The SKU name for the Key Vault"
  type        = string
  default     = "standard"
}
variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for the Key Vault"
  type        = bool
  default     = true
}
variable "public_network_access_enabled" {
  description = "Enable public network access for the Key Vault"
  type        = bool
  default     = false
}
variable "enabled_for_deployment" {
  description = "Enable the Key Vault for deployment"
  type        = bool
  default     = true
}
variable "enable_for_disk_encryption" {
  description = "Enable the Key Vault for disk encryption"
  type        = bool
  default     = true
}
variable "enabled_for_template_deployment" {
  description = "Enable the Key Vault for template deployment"
  type        = bool
  default     = true
}
variable "subnet_id" {
  description = "The ID of the subnet for the Key Vault private endpoint"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used
}
variable "private_endpoint_enabled" {
  description = "Enable private endpoint for the Key Vault"
  type        = bool
  default     = false
}
variable "vnet_id" {
  description = "The ID of the virtual network to which the Key Vault will be associated"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used  
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostic settings"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used  
}
variable "log_categories" {
  description = "List of log categories for diagnostic settings"
  type        = list(string)
  default     = ["AuditEvent"] # Default categories, can be customized  
}
variable "metric_categories" {
  description = "List of metric categories for diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"] # Default categories, can be customized    
}
variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}
variable "enable_kv_diagnostics" {
  description = "Enable diagnostic settings for the Key Vault"
  type        = bool
  default     = false
}
# variable "prevent_kv_deletion" {
#   description = "Prevent deletion of the Key Vault"
#   type        = bool
#   default     = false
# }