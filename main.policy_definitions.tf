resource "azapi_resource" "policy_definitions" {
  for_each  = local.policy_definitions
  type      = "Microsoft.Authorization/policyDefinitions@2023-04-01"
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  name      = each.value.definition.name
  body = {
    properties = each.value.definition.properties
  }
  depends_on = [
    azapi_resource.mg0,
    azapi_resource.mg1,
    azapi_resource.mg2,
    azapi_resource.mg3,
    azapi_resource.mg4,
    azapi_resource.mg5,
    azapi_resource.mg6,
  ]
}
