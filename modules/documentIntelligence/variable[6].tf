variable "env" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
variable "kind" { type = string }

# Existing network references
variable "vnet_id" { type = string }   # e.g., /subscriptions/.../virtualNetworks/...
variable "subnet_id" { type = string } # e.g., /subscriptions/.../subnets/snet-di-pe

# Cognitive Account settings
variable "di_name_prefix" { type = string }
variable "sku_name" {
  type    = string
  default = "S0"
} # Doc Intelligence typical tier
variable "custom_subdomain_name" {
  type    = string
  default = null
}