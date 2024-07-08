module "policy_assignment" {
  source   = "./modules/azapi_helper"
  for_each = local.policy_assignments

  name                    = each.value.assignment.name
  type                    = "Microsoft.Authorization/policyAssignments@2024-04-01"
  ignore_missing_property = true
  identity = lookup(each.value.assignment, "identity", null) != null ? {
    type         = each.value.assignment.identity.type
    identity_ids = lookup(each.value.assignment.identity, "identity_ids", null)
  } : null

  body = {
    properties = {
      description     = lookup(each.value.assignment.properties, "description", null)
      displayName     = lookup(each.value.assignment.properties, "displayName", null)
      enforcementMode = lookup(each.value.assignment.properties, "enforcementMode", null)
      metadata = lookup(each.value.assignment.properties, "metadata", {
        createdBy = ""
        createdOn = ""
        updatedBy = ""
        updatedOn = ""
      })
      nonComplianceMessages = lookup(each.value.assignment.properties, "nonComplianceMessages", null)
      notScopes             = lookup(each.value.assignment.properties, "notScopes", null)
      overrides             = lookup(each.value.assignment.properties, "overrides", null)
      parameters            = lookup(each.value.assignment.properties, "parameters", null)
      policyDefinitionId    = lookup(each.value.assignment.properties, "policyDefinitionId", null)
      resourceSelectors     = lookup(each.value.assignment.properties, "resourceSelectors", null)
    }
  }
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  location  = var.location

  timeouts = var.timeouts.policy_assignment

  replace_triggered_by = [
    lookup(each.value.assignment.properties, "policyDefinitionId", null),
    var.location,
  ]

  depends_on = [
    time_sleep.after_policy_set_definitions
  ]
}
