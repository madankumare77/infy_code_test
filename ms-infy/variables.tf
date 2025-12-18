
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
  default = "a0b36c09-679f-4dfb-829f-3b6685282dae"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
  default = "16b3c013-d300-468d-ac64-7eda0820b6d3"
}

############################################
# Safety switches
############################################
variable "allow_destroy" {
  type        = bool
  description = "Safety guard. Any deletion (subnet/NSG/association/VNet) requires allow_destroy=true."
  default     = false
}
############################################
# NOTE: The module uses `locals` as the authoritative source
# for resource create/destroy flags. Per-resource `create` keys
# are defined in `ms-infy/locals.tf` (vnets, subnets, nsgs, associations,
# and resource_group). The `allow_destroy` variable remains as a
# global safety guard and must be set to true to permit deletions.
############################################

############################################
# NOTE: The module now uses `locals` as the authoritative source
# for resource definitions (vnets, nsgs, associations, resource_group)
# The previous large variable blocks (resource_group, virtual_networks,
# nsg_configs, nsg_associations) were removed to make `locals.tf` the
# single source of defaults. If you rely on external overrides, we can
# reintroduce a small set of override variables instead of full tfvars.
############################################
