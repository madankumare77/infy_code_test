resource "azurerm_private_endpoint" "this" {
  name                = "pvt-endpoint-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "pvt-endpoint-${var.name}-psc"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = [var.subresource_name]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  # private_dns_zone_group {
  #   name                 = "default"
  #   private_dns_zone_ids = [var.private_dns_zone_id]
  # }
}

variable "private_dns_zone_id" {
  description = "The ID of the Private DNS Zone to link the Private Endpoint to."
  type        = string
  default     = ""
}


output "pr_id" {
  value = azurerm_private_endpoint.this.id
}


