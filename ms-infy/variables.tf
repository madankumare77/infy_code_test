
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
# Per-resource creation switches
############################################
variable "create_resource_group" {
  type        = bool
  description = "When false, the module will not create or read resource group resources. Uses locals instead."
  default     = true
}

variable "create_vnets" {
  type        = bool
  description = "When false, VNets will not be created."
  default     = true
}

variable "create_nsgs" {
  type        = bool
  description = "When false, NSG creation (create_nsg=true entries) will be disabled. Existing/imported NSGs are still read."
  default     = true
}

variable "create_associations" {
  type        = bool
  description = "When false, NSG<->subnet associations will not be created."
  default     = true
}

############################################
# NOTE: The module now uses `locals` as the authoritative source
# for resource definitions (vnets, nsgs, associations, resource_group)
# The previous large variable blocks (resource_group, virtual_networks,
# nsg_configs, nsg_associations) were removed to make `locals.tf` the
# single source of defaults. If you rely on external overrides, we can
# reintroduce a small set of override variables instead of full tfvars.
############################################
