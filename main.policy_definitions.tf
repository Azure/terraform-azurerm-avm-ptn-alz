resource "azapi_resource" "policy_definitions" {
  for_each = local.policy_definitions

  type = "Microsoft.Authorization/policyDefinitions@2023-04-01"
  body = {
    properties = each.value.definition.properties
  }
  name      = each.value.definition.name
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  retry = length(var.retry.policy_definitions.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.policy_definitions.error_message_regex
    interval_seconds     = var.retry.policy_definitions.interval_seconds
    max_interval_seconds = var.retry.policy_definitions.max_interval_seconds
    multiplier           = var.retry.policy_definitions.multiplier
    randomization_factor = var.retry.policy_definitions.randomization_factor
  } : null

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
