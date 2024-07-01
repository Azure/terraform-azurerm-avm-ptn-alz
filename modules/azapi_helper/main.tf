resource "azapi_resource" "this" {
  type      = var.type
  name      = var.name
  parent_id = var.parent_id
  location  = var.location
  body = {
    properties = var.properties
  }

  response_export_values = var.response_export_values

  lifecycle {
    replace_triggered_by = [
      terraform_data.replace_trigger
    ]
  }
}

resource "terraform_data" "replace_trigger" {
  input = var.replace_triggered_by
}
