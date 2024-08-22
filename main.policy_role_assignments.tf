resource "azapi_resource" "policy_role_assignments" {
  for_each = local.policy_role_assignments

  type = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = each.value.principal_id
      roleDefinitionId = each.value.role_definition_id
      description      = "Created by ALZ Terraform provider. Assignment required for Azure Policy."
      principalType    = "ServicePrincipal"
    }
  }
  name      = each.key
  parent_id = each.value.scope
  replace_triggered_by = [
    each.value.principal_id,
    each.value.role_definition_id,
  ]
  retry = length(var.retry.policy_role_assignments.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.policy_role_assignments.error_message_regex
    interval_seconds     = var.retry.policy_role_assignments.interval_seconds
    max_interval_seconds = var.retry.policy_role_assignments.max_interval_seconds
    multiplier           = var.retry.policy_role_assignments.multiplier
    randomization_factor = var.retry.policy_role_assignments.randomization_factor
  } : null

  timeouts {
    create = var.timeouts.policy_role_assignment.create
    delete = var.timeouts.policy_role_assignment.delete
    read   = var.timeouts.policy_role_assignment.read
    update = var.timeouts.policy_role_assignment.update
  }
}
