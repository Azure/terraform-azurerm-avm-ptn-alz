module "policy_definitions" {
  source    = "./modules/azapi_helper"
  for_each  = local.policy_definitions
  type      = "Microsoft.Authorization/policyDefinitions@2023-04-01"
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  name      = each.value.definition.name
  body = {
    properties = each.value.definition.properties
  }
  depends_on = [
    time_sleep.after_management_groups
  ]
}
