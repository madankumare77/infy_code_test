variable "env" { type = string }
variable "name_prefix" { type = string }
variable "location" { type = string }
variable "rg_name" { type = string }
variable "kind" { type = string }
variable "sku_name" { type = string }
variable "UserAssigned_identity" {
  type    = string
  default = null
}