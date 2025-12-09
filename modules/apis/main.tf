locals {
  # Flatten operations for easier processing
  api_operations = flatten([
    for api_name, api_config in var.apis : [
      for op_name, op in api_config.operations : {
        api_name       = api_name
        operation_name = op_name
        operation      = op
      }
    ]
  ])
}

# Create APIs within the APIM instance
resource "azurerm_api_management_api" "this" {
  for_each            = var.apis
  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  revision            = "1"
  display_name        = each.key
  path                = each.key
  protocols           = ["https"]
  service_url         = each.value.service_url
}

# Create API Operations
resource "azurerm_api_management_api_operation" "this" {
  for_each = { for op in local.api_operations : "${op.api_name}-${op.operation.operation_id}" => op }

  operation_id        = each.value.operation.operation_id
  api_name            = azurerm_api_management_api.this[each.value.api_name].name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = "${each.value.operation.operation_id}-operation"
  method              = each.value.operation.method
  url_template        = each.value.operation.url_template
  description         = each.value.operation.description

  dynamic "template_parameter" {
    for_each = each.value.operation.template_parameter
    content {
      name     = template_parameter.value.name
      type     = template_parameter.value.type
      required = template_parameter.value.required
    }
  }

  dynamic "response" {
    for_each = each.value.operation.responses
    content {
      status_code = response.value.status_code
      description = response.value.description
    }
  }
}

# Create products (optional)
resource "azurerm_api_management_product" "this" {
  for_each              = var.apis
  product_id            = each.key
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = "${each.key}-Product"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Link APIs to products
resource "azurerm_api_management_product_api" "this" {
  for_each            = var.apis
  api_name            = azurerm_api_management_api.this[each.key].name
  product_id          = azurerm_api_management_product.this[each.key].product_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}