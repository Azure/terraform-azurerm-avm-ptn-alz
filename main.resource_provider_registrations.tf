resource "azapi_resource_action" "management_group_resource_provider_registrations" {
  for_each = local.management_group_resource_provider_registrations

  action      = "providers/${each.value.resource_provider_namespace}/register"
  method      = "POST"
  resource_id = "/providers/Microsoft.Management/managementGroups/${each.value.management_group_name}"
  type        = var.resource_types.management_group

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
