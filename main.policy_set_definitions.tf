resource "azapi_resource" "policy_set_definitions" {
  for_each = local.policy_set_definitions

  name      = each.value.set_definition.name
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  type      = "Microsoft.Authorization/policySetDefinitions@2023-04-01"
  body = {
    properties = each.value.set_definition.properties
  }
  replace_triggers_external_values = lookup(each.value.set_definition.properties, "policyType", null)
  retry = var.retries.policy_set_definitions.error_message_regex != null ? {
    error_message_regex  = var.retries.policy_set_definitions.error_message_regex
    interval_seconds     = lookup(var.retries.policy_set_definitions, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.policy_set_definitions, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.policy_set_definitions, "multiplier", null)
    randomization_factor = lookup(var.retries.policy_set_definitions, "randomization_factor", null)
  } : null

  timeouts {
    create = var.timeouts.policy_set_definition.create
    delete = var.timeouts.policy_set_definition.delete
    read   = var.timeouts.policy_set_definition.read
    update = var.timeouts.policy_set_definition.update
  }

  depends_on = [
    time_sleep.after_policy_definitions
  ]
}
