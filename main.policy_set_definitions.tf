resource "azapi_resource" "policy_set_definitions" {
  for_each  = local.policy_set_definitions
  type      = "Microsoft.Authorization/policySetDefinitions@2023-04-01"
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  name      = each.value.set_definition.name
  body = {
    properties = each.value.set_definition.properties
  }
  depends_on = [
    azapi_resource.policy_definitions
  ]
}
