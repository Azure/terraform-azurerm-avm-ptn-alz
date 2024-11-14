resource "terraform_data" "policy_role_assignments_dependencies" {
  input = sha256(jsonencode(var.dependencies.policy_role_assignments))
}

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
  replace_triggers_external_values = [
    each.value.principal_id,
    each.value.role_definition_id,
  ]
  retry = var.retries.policy_role_assignments.error_message_regex != null ? {
    error_message_regex  = var.retries.policy_role_assignments.error_message_regex
    interval_seconds     = lookup(var.retries.policy_role_assignments, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.policy_role_assignments, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.policy_role_assignments, "multiplier", null)
    randomization_factor = lookup(var.retries.policy_role_assignments, "randomization_factor", null)
  } : null

  timeouts {
    create = var.timeouts.policy_role_assignment.create
    delete = var.timeouts.policy_role_assignment.delete
    read   = var.timeouts.policy_role_assignment.read
    update = var.timeouts.policy_role_assignment.update
  }

  depends_on = [terraform_data.policy_role_assignments_dependencies]

  lifecycle {
    # https://github.com/Azure/terraform-provider-azapi/issues/671
    ignore_changes = [output.properties.updatedOn]
  }
}
