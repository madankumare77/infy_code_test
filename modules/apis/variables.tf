# variables.tf
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "api_management_name" {
  description = "Name of the API Management instance"
  type        = string
}

variable "apis" {
  description = "Map of APIs and their operations"
  type = map(object({
    service_url = optional(string, "https://example.com/api")
    operations = map(object({
      operation_id = string
      method       = string
      url_template = string
      description  = optional(string, "API operation")
      template_parameter = optional(list(object({
        name     = string
        type     = string
        required = bool
      })), [])
      responses = optional(list(object({
        status_code = number
        description = optional(string, "Successful response")
      })), [{ status_code = 200, description = "Successful response" }])
    }))
  }))
}