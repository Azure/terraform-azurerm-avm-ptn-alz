resource "azapi_resource" "this" {
  type                    = var.type
  name                    = var.name
  parent_id               = var.parent_id
  location                = var.location
  body                    = var.body
  ignore_missing_property = var.ignore_missing_property

  dynamic "identity" {
    for_each = var.identity == null ? [] : var.identity.type != "None" ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
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
