resource "azapi_resource" "policy_definitions" {
  for_each = local.policy_definitions

  name      = each.value.definition.name
  parent_id = "${coalesce(lookup(var.parent_id_overrides.policy_definitions, each.key, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.mg}"
  type      = var.resource_types.policy_definition
  body = {
    properties = each.value.definition.properties
  }
  response_export_values = []
  retry = var.retries.policy_definitions.error_message_regex != null ? {
    error_message_regex  = var.retries.policy_definitions.error_message_regex
    interval_seconds     = lookup(var.retries.policy_definitions, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.policy_definitions, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.policy_definitions, "multiplier", null)
    randomization_factor = lookup(var.retries.policy_definitions, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.policy_definitions

  timeouts {
    create = var.timeouts.policy_definition.create
    delete = var.timeouts.policy_definition.delete
    read   = var.timeouts.policy_definition.read
    update = var.timeouts.policy_definition.update
  }

  depends_on = [
    time_sleep.after_management_groups
  ]
}
