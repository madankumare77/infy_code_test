variable "vnet_name_prefix" {
  description = "The name of the virtual network to which the subnet belongs"
  type        = string

}
variable "address_space" {
  description = "The address prefix for the virtual network"
  type        = string
}
variable "location" {
  description = "The Azure region where the subnet will be created"
  type        = string

}
variable "rg_name" {
  description = "The name of the resource group where the subnet will be created"
  type        = string
}
variable "subnet_configs" {
  description = "A map of subnet configurations for the virtual network"
  type = map(object({
    address_prefix     = string
    create_nsg         = optional(bool, false)
    service_endpoints  = optional(list(string), [])
    create_route_table = optional(bool, false)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }), null)
  }))
  default = {}
}
variable "env" {
  description = "The environment for which the virtual network is being created (e.g., dev, prod)"
  type        = string
}

variable "enable_ddos_protection" {
  description = "Flag to enable DDoS protection for the virtual network"
  type        = bool
  default     = true
}
variable "dns_servers" {
  description = "List of DNS servers for the virtual network"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the virtual network"
  type        = map(string)
  default     = {}
}