variable "law_name" {
  type        = string
  description = "The name of the Log Analytics Workspace"
}
variable "rg_name" {
  type        = string
  description = "The name of the resource group where the Log Analytics Workspace will be created"
}
variable "location" {
  type        = string
  description = "The Azure region where the Log Analytics Workspace will be created"
}
variable "env" {
  type        = string
  description = "The name of the environment"
}
variable "law_sku" {
  type        = string
  description = "The SKU for the Log Analytics Workspace"
  default     = "PerGB2018"
}
variable "retention_in_days" {
  type        = number
  description = "The number of days to retain data in the Log Analytics Workspace"
  default     = 30
}
variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Log Analytics Workspace"
}