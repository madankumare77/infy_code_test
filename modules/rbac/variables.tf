variable "scope" {
  type        = string
  description = "(Required) Provide the `Resource ID` of the `Resource` in which built-in Role needs to be assigned."
}

variable "principal_id" {
  type        = string
  description = "(Required) Provide the `Object ID` of the `Principal` `(User, Group or Service Principal)` to assign the Role to. The Principal ID is also known as the `Object ID`."
}

variable "principal_type" {
  type        = string
  description = "(Optional) The type of the principal_id. Possible values are User, Group and ServicePrincipal. Changing this forces a new resource to be created."
  default     = null
}

variable "role_definition_id" {
  type        = string
  description = "(Required*) Provide the \"ID\" of a built-in Role. See [list of built-in Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles). Only one of `role_definition_name` or `role_definition_id` is required: if both are provided, it will return an error (valid input is: Id XOR Name)."
  default     = null
}

variable "role_definition_name" {
  type        = string
  description = "(Required*) Provide the \"Name\" of a built-in Role. See [list of built-in Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles). Only one of `role_definition_name` or `role_definition_id` is required: if both are provided, it will return an error (valid input is: Id XOR Name)."
  default     = null
}

variable "name" {
  type        = string
  description = "(Optional) A unique UUID/GUID for this Role Assignment - one will be generated if not specified."
  default     = null
}

variable "description" {
  type        = string
  description = "(Optional) A description for this Role Assignment."
  default     = null
}

variable "skip_service_principal_aad_check" {
  type        = bool
  description = "(Optional) If the `principal_id` is a newly provisioned `Service Principal` set this value to `true` to skip the `Azure Active Directory` check: it may fail due to replication lag. This argument is only valid if the `principal_id` is of type `Service Principal`."
  default     = false
}

variable "delegated_managed_identity_resource_id" {
  type        = string
  description = "(Optional) Provide the delegated `Azure Resource Id` which contains a `Managed Identity`. This field is used in cross tenant scenario. The `principal_id` in this scenario must be the `object_id` of the `Managed Identity`"
  default     = null
}

variable "condition" {
  type        = string
  description = "(Optional) Provide the condition that limits the resources that the role can be assigned to."
  default     = null
}

variable "condition_version" {
  type        = string
  description = "(Optional) The version of the condition. Possible values are `1.0` or `2.0`."
  default     = null
}