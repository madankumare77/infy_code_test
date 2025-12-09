variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group"
  type        = string

}

variable "location" {
  description = "The Azure region where the storage account will be created"
  type        = string

}

variable "env" {
  description = "The environment for which the storage account is being created (e.g., dev, prod)"
  type        = string

}

variable "snet_id" {
  description = "The ID of the subnet to which the storage account will be associated"
  type        = string
}

variable "vnet_id" {
  description = "The ID of the virtual network to which the storage account will be associated"
  type        = string
}

variable "account_tier" {
  description = "The performance tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "account_kind" {
  description = "The kind of storage account"
  type        = string
  default     = "StorageV2"
}

variable "account_replication_type" {
  description = "The replication type of the storage account"
  type        = string
  default     = "LRS"
}

variable "private_endpoint_enabled" {
  description = "Enable or disable private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "subresource_names" {
  description = "The subresource names for the private service connection"
  type        = list(string)
  default     = ["blob", "file", "table", "queue"]
}

variable "public_network_access_enabled" {
  description = "Enable or disable public network access for the storage account"
  type        = bool
  default     = false
}

variable "https_traffic_only_enabled" {
  description = "Enable or disable HTTPS traffic only for the storage account"
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Enable or disable shared access key for the storage account"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum TLS version for the storage account"
  type        = string
  default     = "TLS1_2"
}

variable "psc_is_manual_connection" {
  description = "Indicates whether the private service connection is manual"
  type        = bool
  default     = false
}

variable "enable_blob_versioning" {
  type    = bool
  default = true # Change to false if you want to disable
}
variable "delete_retention_days" {
  description = "The number of days to retain deleted blobs"
  type        = number
  default     = 7
}
variable "infrastructure_encryption_enabled" {
  description = "Enable or disable infrastructure encryption for the storage account"
  type        = bool
  default     = false
}
variable "tags" {
  description = "A map of tags to assign to the storage account"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostic settings"
  type        = string
  default     = ""
}

variable "log_categories" {
  description = "List of log categories to enable for the storage account diagnostic settings"
  type        = list(string)
  default     = ["StorageRead", "StorageWrite"]
}

variable "metric_categories" {
  description = "List of metric categories to enable for the storage account diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "enable_storage_diagnostics" {
  description = "Enable or disable storage diagnostics"
  type        = bool
  default     = false
}