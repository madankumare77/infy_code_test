variable "env" {
  description = "The name of the environment"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "lock_level" {
  type = string
}

variable "enable_storage_account" {
  description = "Enable or disable Storage Account module"
  type        = bool
  default     = false
}
variable "enable_function_app" {
  description = "Enable or disable Function App module"
  type        = bool
  default     = false
}
variable "enable_aks" {
  description = "Enable or disable AKS module"
  type        = bool
  default     = false
}
variable "enable_kv" {
  description = "Enable or disable Key Vault module"
  type        = bool
  default     = false
}
variable "enable_postgresql_flex" {
  description = "Enable or disable PostgreSQL Flexible Server module"
  type        = bool
  default     = false
}
variable "enable_apim" {
  description = "Enable or disable API Management module"
  type        = bool
  default     = false
}
variable "enable_redis_cache" {
  description = "Enable or disable Redis Cache module"
  type        = bool
  default     = false
}
variable "enable_sqlmi" {
  description = "Enable or disable SQL Managed Instance module"
  type        = bool
  default     = false
}
variable "enable_virtual_networks" {
  type    = bool
  default = false
}
variable "enable_azure_documentdb" {
  description = "Enable or disable Azure DocumentDB (CosmosDB) module"
  type        = bool
  default     = false
}
variable "enable_di_account" {
  description = "A map of tags to assign to the resources"
  type        = bool
  default     = false
}
variable "enable_azure_openai" {
  description = "Enable or disable Azure OpenAI module"
  type        = bool
  default     = false
}
variable "enable_log_analytics_workspace" {
  description = "Enable or disable Log Analytics Workspace module"
  type        = bool
  default     = false
}
variable "enable_aml_workspace" {
  description = "Enable or disable Azure Machine Learning Workspace module"
  type        = bool
  default     = false
}
variable "enable_UserAssignedIdenti" {
  description = "Enable or disable User Assigned Identity module"
  type        = bool
  default     = false
}
variable "enable_cosmos" {
  type    = bool
  default = false
}
variable "enable_private_dns_zone" {
  description = "Enable creation of Private DNS Zone"
  type        = bool
  default     = false
}
variable "enable_appinsights" {
  description = "Enable or disable Application Insights module"
  type        = bool
  default     = false
}

variable "enable_nsg" {
  description = "Enable creation of Network Security Groups"
  type        = bool
  default     = false
}
variable "enable_rbac" {
  type    = bool
  default = false
}
variable "enable_diagnostics_settings" {
  type    = bool
  default = false
}
variable "enable_private_endpoints" {
  type    = bool
  default = false
}
variable "rg_lock_enable" {
  type    = bool
  default = false
}

variable "enable_nsg_association" {
  type    = bool
  default = true
}