module "policy_role_assignments" {
  source    = "./modules/azapi_helper"
  for_each  = local.policy_role_assignments
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = each.key
  parent_id = each.value.scope
  body = {
    properties = {
      principalId      = each.value.principal_id
      roleDefinitionId = each.value.role_definition_id
      description      = "Created by ALZ Terraform provider. Assignment required for Azure Policy."
      principalType    = "ServicePrincipal"
    }
  }

  timeouts = var.timeouts.policy_role_assignment

  replace_triggered_by = [
    each.value.principal_id,
    each.value.role_definition_id,
  ]
}
