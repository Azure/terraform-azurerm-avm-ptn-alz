resource "azapi_resource" "role_definitions" {
  for_each = local.role_definitions

  type = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  body = {
    properties = {
      assignableScopes = each.value.role_definition.properties.assignableScopes
      description      = each.value.role_definition.properties.description
      permissions      = each.value.role_definition.properties.permissions
      roleName         = "${each.value.role_definition.properties.roleName} (${each.value.mg})"
      type             = each.value.role_definition.properties.type
    }
  }
  name      = each.value.role_definition.name
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  retry = var.retries.role_definitions.error_message_regex != null ? {
    error_message_regex  = var.retries.role_definitions.error_message_regex
    interval_seconds     = lookup(var.retries.role_definitions, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.role_definitions, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.role_definitions, "multiplier", null)
    randomization_factor = lookup(var.retries.role_definitions, "randomization_factor", null)
  } : null

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
