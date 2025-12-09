variable "enable_peering" {
  description = "Enable or disable peering"
  type        = bool
  default     = false
}

variable "hub_vnets" {
  description = "Map of hub VNets"
  type = map(object({
    name            = string
    resource_group  = string
    vnet_id         = string
    subscription_id = optional(string)
  }))
}

variable "spoke_vnets" {
  description = "Map of spoke VNets"
  type = map(object({
    name            = string
    resource_group  = string
    vnet_id         = string
    subscription_id = optional(string)
  }))
}