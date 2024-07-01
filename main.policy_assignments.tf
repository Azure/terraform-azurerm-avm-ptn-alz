module "policy_assignment" {
  source   = "./modules/azapi_helper"
  for_each = local.policy_assignments

  name = each.value.assignment.name
  type = "Microsoft.Authorization/policyAssignments@2024-04-01"
  properties = {
    description           = lookup(each.value.assignment.properties, "description", null)
    displayName           = lookup(each.value.assignment.properties, "displayName", null)
    enforcementMode       = lookup(each.value.assignment.properties, "enforcementMode", null)
    metadata              = lookup(each.value.assignment.properties, "metadata", null)
    nonComplianceMessages = lookup(each.value.assignment.properties, "nonComplianceMessages", null)
    notScopes             = lookup(each.value.assignment.properties, "notScopes", null)
    overrides             = lookup(each.value.assignment.properties, "overrides", null)
    parameters            = lookup(each.value.assignment.properties, "parameters", null)
    policyDefinitionId    = lookup(each.value.assignment.properties, "policyDefinitionId", null)
    resourceSelectors     = lookup(each.value.assignment.properties, "resourceSelectors", null)
  }
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  location  = var.location

  replace_triggered_by = [
    each.value.assignment.name,
    lookup(each.value.assignment.properties, "policyDefinitionId", null),
    var.location,
  ]

  response_export_values = [
    "identity.principalId",
    "identity.tenantId",
    "identity.type",
  ]

  depends_on = [
    azapi_resource.policy_set_definitions
  ]
}


# resource "azapi_resource" "policy_assignments" {
#   for_each  = local.policy_assignments
#   type      = "Microsoft.Authorization/policyAssignments@2024-04-01"
#   parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
#   name      = each.value.assignment.name
#   body = {
#     properties = {
#       description           = lookup(each.value.assignment.properties, "description", null)
#       displayName           = lookup(each.value.assignment.properties, "displayName", null)
#       enforcementMode       = lookup(each.value.assignment.properties, "enforcementMode", null)
#       metadata              = lookup(each.value.assignment.properties, "metadata", null)
#       nonComplianceMessages = lookup(each.value.assignment.properties, "nonComplianceMessages", null)
#       notScopes             = lookup(each.value.assignment.properties, "notScopes", null)
#       overrides             = lookup(each.value.assignment.properties, "overrides", null)
#       parameters            = lookup(each.value.assignment.properties, "parameters", null)
#       policyDefinitionId    = lookup(each.value.assignment.properties, "policyDefinitionId", null)
#       resourceSelectors     = lookup(each.value.assignment.properties, "resourceSelectors", null)
#     }
#   }
#   response_export_values = [
#     "identity.principalId",
#     "identity.tenantId",
#     "identity.type",
#   ]
#   depends_on = [
#     azapi_resource.policy_set_definitions
#   ]
# }
