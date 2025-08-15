resource "azapi_resource" "subscription_placement" {
  for_each = var.subscription_placement

  name           = each.value.subscription_id
  parent_id      = "/providers/Microsoft.Management/managementGroups/${each.value.management_group_name}"
  type           = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = var.retries.subscription_placement.error_message_regex != null ? {
    error_message_regex  = var.retries.subscription_placement.error_message_regex
    interval_seconds     = lookup(var.retries.subscription_placement, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.subscription_placement, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.subscription_placement, "multiplier", null)
    randomization_factor = lookup(var.retries.subscription_placement, "randomization_factor", null)
  } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.management_groups_level_0,
    azapi_resource.management_groups_level_1,
    azapi_resource.management_groups_level_2,
    azapi_resource.management_groups_level_3,
    azapi_resource.management_groups_level_4,
    azapi_resource.management_groups_level_5,
    azapi_resource.management_groups_level_6,
  ]
}
