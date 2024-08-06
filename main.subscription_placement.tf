resource "azapi_resource" "subscription_placement" {
  for_each = var.subscription_placement

  type      = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
  name      = each.value.subscription_id
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.management_group_name}"
}
