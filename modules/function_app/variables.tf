variable "function_apps" {
  description = "Map of function app configs"
  type = map(object({
    os_type                       = string # "Windows" or "Linux"
    runtime_stack                 = string # ".NET" for Windows, "Java|11" for Linux
    storage_required              = optional(bool, false)
    public_network_access_enabled = optional(bool, false)    # Default to true
    subnet_id                     = optional(string, "")     # Subnet ID for VNet integration
    vnet_id                       = optional(string, "")     # VNet ID for VNet integration
    sku_name                      = optional(string, "P1v2") # Default SKU for Premium v2
    private_endpoint_enabled      = optional(bool, false)    # Whether to create a private endpoint
    tags                          = optional(map(string), {})
  }))
}

variable "rg_name" { type = string }
variable "location" { type = string }
variable "env" { type = string }