module "role_definitions" {
  source    = "./modules/azapi_helper"
  for_each  = local.role_definitions
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  name      = each.value.role_definition.name
  body = {
    properties = {
      assignableScopes = each.value.role_definition.properties.assignableScopes
      description      = each.value.role_definition.properties.description
      permissions      = each.value.role_definition.properties.permissions
      roleName         = "${each.value.role_definition.properties.roleName} (${each.value.mg})"
      type             = each.value.role_definition.properties.type
    }
  }

  timeouts = var.timeouts.role_definition

  depends_on = [
    time_sleep.after_management_groups
  ]
}
