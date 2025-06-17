resource "azapi_resource" "policy_exemptions" {
  for_each = var.policy_exemptions

  type = "Microsoft.Authorization/policyExemptions@2022-07-01-preview"
  body = {
    properties = {
      exemptionCategory            = each.value.exemption_category
      policyAssignmentId           = coalesce(each.value.assignment_resource_id, azapi_resource.policy_assignments[each.value.assignment_key].id)
      assignmentScopeValidation    = each.value.assignment_scope_validation
      description                  = each.value.description
      displayName                  = each.value.display_name
      expiresOn                    = each.value.expires_on
      policyDefinitionReferenceIds = each.value.policy_definition_reference_ids
      resourceSelectors = [
        for resource_selector in each.value.resource_selectors : {
          name = resource_selector.name
          selectors = [
            for selector in resource_selector.resource_selector_selectors : {
              kind  = selector.kind
              in    = selector.in
              notIn = selector.not_in
            }
          ]
        }
      ]
    }
  }
  name      = each.value.name
  parent_id = each.value.exemption_scope
  tags      = each.value.tags
}
