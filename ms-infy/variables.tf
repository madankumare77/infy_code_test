
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

############################################
# Safety switches
############################################
variable "enabled" {
  type        = bool
  description = "Global switch. If false, ALL managed resources are removed on apply (requires allow_destroy=true)."
  default     = true
}

variable "allow_destroy" {
  type        = bool
  description = "Safety guard. Any deletion (subnet/NSG/association/VNet) requires allow_destroy=true."
  default     = false
}

############################################
# Resource Group (create or import)
############################################
variable "resource_group" {
  description = "Create RG with AVM OR import existing RG by name."
  type = object({
    enabled  = optional(bool, true)
    create   = bool
    name     = string
    location = string
    tags     = optional(map(string), {})
  })
}

############################################
# VNets + Subnets (your structure, moved to tfvars)
# Minimal additions:
# - enabled on vnet level and subnet level for selective destroy
############################################
variable "virtual_networks" {
  description = "Nested map: outer grouping key -> vnet key -> vnet config."
  type = map(
    map(object({
      enabled                = optional(bool, true)
      location               = string
      address_space          = string
      enable_ddos_protection = bool
      dns_servers            = optional(list(string), [])
      tags                   = optional(map(string), {})

      subnet_configs = map(object({
        enabled           = optional(bool, true)
        address_prefix    = string
        service_endpoints = optional(list(string), [])

        delegation = optional(object({
          name = string
          service_delegation = object({
            name    = string
            actions = list(string)
          })
        }))

        # Common portal policy toggles for private endpoints/private link services
        private_endpoint_network_policies_enabled     = optional(bool, true)
        private_link_service_network_policies_enabled = optional(bool, true)

        # Optional future-ready
        route_table_id = optional(string)
      }))
    }))
  )

  validation {
    condition = alltrue([
      for outer_k, outer_v in var.virtual_networks :
      alltrue([
        for vnet_k, vnet in outer_v :
        can(cidrnetmask(vnet.address_space))
      ])
    ])
    error_message = "Each virtual_networks[*][*].address_space must be a valid CIDR, e.g. 10.0.0.0/16."
  }
}

############################################
# NSGs (create with AVM OR import existing)
# NOTE: map keys must be UNIQUE (your example had duplicate nsg1 keys - invalid).
############################################
variable "nsg_configs" {
  description = "Map of NSGs keyed by logical key (unique). Can create or reference existing."
  type = map(object({
    enabled    = optional(bool, true)
    create_nsg = bool

    # Name of the NSG when creating. For imported NSGs, prefer providing
    # `existing_nsg_name` or `existing_nsg_id` instead of `nsg_name`.
    nsg_name = optional(string)
    location = optional(string)
    rg_name  = optional(string)
    tags     = optional(map(string), {})

    # For existing NSG
    existing_nsg_id   = optional(string)
    existing_rg_name  = optional(string)
    existing_nsg_name = optional(string)

    # Rules only used when create_nsg=true
    security_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string # Inbound/Outbound
      access                     = string # Allow/Deny
      protocol                   = string # Tcp/Udp/Icmp/*/Any
      source_address_prefix      = string
      destination_address_prefix = string
      source_port_range          = string
      destination_port_range     = string
      description                = optional(string)
    })), [])
  }))

  validation {
    condition = alltrue([
      for k, n in var.nsg_configs : (
        # If create_nsg=true then nsg_name must be provided.
        n.create_nsg ? (try(n.nsg_name, "") != "") : (
          # If create_nsg=false then either existing_nsg_id or existing_nsg_name must be provided.
          (try(n.existing_nsg_id, null) != null) || (try(n.existing_nsg_name, null) != null)
        )
      )
    ])

    error_message = "Each nsg_configs entry must either: provide 'nsg_name' when 'create_nsg=true', or provide 'existing_nsg_name' or 'existing_nsg_id' when 'create_nsg=false'."
  }

  validation {
    condition = alltrue([
      for k, nsg in var.nsg_configs :
      alltrue([for r in try(nsg.security_rules, []) : r.priority >= 100 && r.priority <= 4096])
    ])
    error_message = "NSG rule priority must be between 100 and 4096."
  }
}

############################################
# NSG <-> Subnet associations (tfvars-driven)
# This gives full flexibility:
# - create 1-2 NSGs
# - attach any NSG to any subnet(s)
# - works whether NSG is created or imported
############################################
variable "nsg_associations" {
  description = "Map of association configs. Each entry attaches one NSG to one subnet."
  type = map(object({
    enabled    = optional(bool, true)
    vnet_key   = string # e.g. cind-claims
    subnet_key = string # e.g. cind-pvt
    nsg_key    = string # e.g. nsg_created or nsg_existing
  }))
  default = {}
}
