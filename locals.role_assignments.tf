locals {
  role_assignment_owned_role_definition_ids = {
    for key, assignment in var.management_group_role_assignments : key => var.role_assignment_definition_lookup_enabled ? [
      for definition in azapi_resource.role_definitions :
      provider::azapi::tenant_resource_id("Microsoft.Authorization/roleDefinitions", [definition.name])
      if definition.body.properties.roleName == assignment.role_definition_id_or_name &&
      lower(definition.parent_id) == lower(provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [assignment.management_group_name])) &&
      contains(
        [for scope in definition.body.properties.assignableScopes : lower(scope)],
        lower(provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [assignment.management_group_name]))
      )
    ] : []
  }
}
