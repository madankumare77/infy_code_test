variable "aks_name_prefix" {}
variable "rg_name" {
  description = "The name of the resource group where the AKS cluster will be created"
  type        = string
}
variable "env" {
  description = "The name of the environment"
  type        = string
}
variable "location" {}
variable "kubernetes_version" {}
variable "private_cluster" {}
variable "network_plugin" {}
variable "load_balancer_sku" {}
variable "os_sku" {}
variable "node_os_disk_type" {}
variable "enable_host_encryption" {}
variable "vnet_subnet_id" {
  description = "The ID of the subnet in which the AKS cluster will be deployed"
  type        = string

}

# Existing variables...
variable "default_node_pool" {
  type = object({
    name    = string
    vm_size = string
    zones   = list(string)
    #node_count        = number
    min_count    = number
    max_count    = number
    max_pods     = number
    os_disk_size = number
  })
}

variable "additional_node_pools" {
  type = map(object({
    name    = string
    vm_size = string
    #node_count        = number
    min_count    = number
    max_count    = number
    max_pods     = number
    os_disk_size = number
    zones        = list(string)
    aks_os_type  = optional(string, "Linux")
  }))
}
variable "enable_auto_scale" {
  description = "Enable auto-scaling for the AKS cluster"
  type        = bool
  default     = true

}
variable "mode" {
  description = "The mode of the AKS cluster, either 'System' or 'User'."
  type        = string
  default     = "User"

}
variable "aks_service_cidr" {
  description = "The CIDR range for the AKS service network"
  type        = string

}
variable "aks_dns_service_ip" {
  description = "The IP address for the AKS DNS service"
  type        = string
}
variable "aks_identity_type" {
  description = "The type of identity for the AKS cluster, typically 'UserAssigned' or 'SystemAssigned'."
  type        = string
  default     = "UserAssigned"
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for AKS diagnostics"
  type        = string
  default     = ""
}
variable "log_categories" {
  description = "List of log categories to enable for AKS diagnostics"
  type        = list(string)
  default     = ["kube-apiserver", "kube-controller-manager", "kube-scheduler", "kubelet"]
}
variable "metric_categories" {
  description = "List of metric categories to enable for AKS diagnostics"
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "tags" {
  description = "A map of tags to assign to the AKS cluster"
  type        = map(string)
  default     = {}
}