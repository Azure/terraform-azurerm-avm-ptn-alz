resource "azapi_resource" "policy_assignments" {
  for_each = local.policy_assignments

  type = "Microsoft.Authorization/policyAssignments@2024-04-01"
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
  ignore_missing_property = true
  location                = var.location
  name                    = each.value.assignment.name
  parent_id               = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  replace_triggeres_external_values = [
    lookup(each.value.assignment.properties, "policyDefinitionId", null),
    var.location,
  ]
  retry = length(var.retry.policy_assignments.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.policy_assignments.error_message_regex
    interval_seconds     = var.retry.policy_assignments.interval_seconds
    max_interval_seconds = var.retry.policy_assignments.max_interval_seconds
    multiplier           = var.retry.policy_assignments.multiplier
    randomization_factor = var.retry.policy_assignments.randomization_factor
  } : null

  dynamic "identity" {
    for_each = lookup(each.value.assignment, "identity", null) != null ? [each.value.assignment.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  timeouts {
    create = var.timeouts.policy_assignment.create
    delete = var.timeouts.policy_assignment.delete
    read   = var.timeouts.policy_assignment.read
    update = var.timeouts.policy_assignment.update
  }

  depends_on = [
    time_sleep.after_policy_set_definitions
  ]
}
