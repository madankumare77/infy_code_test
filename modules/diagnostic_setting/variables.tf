variable "name" {
  type        = string
  description = "The name of the diagnostic setting."
}
variable "target_resource_id" {
  type        = string
  description = "The ID of the resource to which the diagnostic setting applies."
}
variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics workspace to which logs will be sent."
  default     = null
  nullable    = true
}
variable "log_categories" {
  type = list(string)
}
variable "metric_categories" {
  type = list(string)
}
