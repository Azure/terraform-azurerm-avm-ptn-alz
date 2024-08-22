resource "azapi_resource" "policy_set_definitions" {
  for_each = local.policy_set_definitions

  type = "Microsoft.Authorization/policySetDefinitions@2023-04-01"
  body = {
    properties = each.value.set_definition.properties
  }
  name                             = each.value.set_definition.name
  parent_id                        = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  replace_triggers_external_values = lookup(each.value.set_definition.properties, "policyType", null)
  retry = length(var.retry.policy_set_definitions.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.policy_set_definitions.error_message_regex
    interval_seconds     = var.retry.policy_set_definitions.interval_seconds
    max_interval_seconds = var.retry.policy_set_definitions.max_interval_seconds
    multiplier           = var.retry.policy_set_definitions.multiplier
    randomization_factor = var.retry.policy_set_definitions.randomization_factor
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
