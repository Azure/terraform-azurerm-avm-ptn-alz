# resource "alz_policy_role_assignments" "this" {
#   assignments = local.policy_role_assignments
# }

resource "azapi_resource" "policy_role_assignments" {
  for_each  = local.policy_role_assignments
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${each.value.principal_id}${each.value.role_definition_id}${each.value.scope}")
  parent_id = each.value.scope
  body = {
    properties = {
      principalId      = each.value.principal_id
      roleDefinitionId = each.value.role_definition_id
      description      = "Created by ALZ Terraform provider. Assignment required for Azure Policy."
      principalType    = "ServicePrincipal"
    }
  }
}
