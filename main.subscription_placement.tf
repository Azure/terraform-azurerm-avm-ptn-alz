resource "azapi_resource" "subscription_placement" {
  for_each = var.subscription_placement

  type      = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
  name      = each.value.subscription_id
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.management_group_name}"
  retry = length(var.retry.subscription_placement.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.subscription_placement.error_message_regex
    interval_seconds     = var.retry.subscription_placement.interval_seconds
    max_interval_seconds = var.retry.subscription_placement.max_interval_seconds
    multiplier           = var.retry.subscription_placement.multiplier
    randomization_factor = var.retry.subscription_placement.randomization_factor
  } : null
}
