resource "azapi_resource" "role_definitions" {
  for_each = local.role_definitions

  name      = each.value.role_definition.name
  parent_id = "${coalesce(lookup(var.parent_id_overrides.role_definitions, each.key, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.mg}"
  type      = "Microsoft.Authorization/roleDefinitions@${var.resource_api_versions.role_definition}"
  body = {
    properties = {
      assignableScopes = each.value.role_definition.properties.assignableScopes
      description      = each.value.role_definition.properties.description
      permissions      = each.value.role_definition.properties.permissions
      roleName         = each.value.role_definition.properties.roleName
      type             = each.value.role_definition.properties.type
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry = var.retries.role_definitions.error_message_regex != null ? {
    error_message_regex  = var.retries.role_definitions.error_message_regex
    interval_seconds     = lookup(var.retries.role_definitions, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.role_definitions, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.role_definitions, "multiplier", null)
    randomization_factor = lookup(var.retries.role_definitions, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.role_definitions
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.role_definition.create
    delete = var.timeouts.role_definition.delete
    read   = var.timeouts.role_definition.read
    update = var.timeouts.role_definition.update
  }

  depends_on = [
    time_sleep.after_management_groups
  ]
}
