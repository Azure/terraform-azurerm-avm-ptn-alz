module "policy_set_definitions" {
  source    = "./modules/azapi_helper"
  for_each  = local.policy_set_definitions
  type      = "Microsoft.Authorization/policySetDefinitions@2023-04-01"
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  name      = each.value.set_definition.name
  body = {
    properties = each.value.set_definition.properties
  }
  depends_on = [
    time_sleep.after_policy_definitions
  ]

  timeouts = var.timeouts.policy_set_definition

  replace_triggered_by = [
    lookup(each.value.set_definition.properties, "policyType", null),
  ]
}
