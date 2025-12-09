variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "subnet_id" {}
variable "private_connection_resource_id" {}
variable "subresource_name" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "vnet_id" {
  type    = string
  default = ""
}