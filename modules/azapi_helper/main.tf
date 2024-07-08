resource "azapi_resource" "this" {
  type                    = var.type
  body                    = var.body
  ignore_missing_property = var.ignore_missing_property
  location                = var.location
  name                    = var.name
  parent_id               = var.parent_id
  response_export_values  = var.response_export_values

  dynamic "identity" {
    for_each = var.identity == null ? [] : var.identity.type != "None" ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  lifecycle {
    ignore_changes = [
      body.properties.metadata.createdBy,
      body.properties.metadata.createdOn,
      body.properties.metadata.updatedBy,
      body.properties.metadata.updatedOn,
    ]
    replace_triggered_by = [
      terraform_data.replace_trigger
    ]
  }
}

resource "terraform_data" "replace_trigger" {
  input = var.replace_triggered_by
}
