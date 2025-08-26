resource "terraform_data" "policy_assignments_dependencies" {
  input = sha256(jsonencode(var.dependencies.policy_assignments))
}

resource "azapi_resource" "policy_assignments" {
  for_each = local.policy_assignments_final

  location  = var.location
  name      = each.value.assignment.name
  parent_id = "/providers/Microsoft.Management/managementGroups/${each.value.mg}"
  type      = "Microsoft.Authorization/policyAssignments@${var.resource_api_versions.policy_assignment}"
  body = {
    properties = {
      description     = lookup(each.value.assignment.properties, "description", null)
      displayName     = lookup(each.value.assignment.properties, "displayName", null)
      enforcementMode = lookup(each.value.assignment.properties, "enforcementMode", null)
      metadata = merge(lookup(each.value.assignment.properties, "metadata", {}),
        {
          createdBy = ""
          createdOn = ""
          updatedBy = ""
          updatedOn = ""
        }
      )
      nonComplianceMessages = lookup(each.value.assignment.properties, "nonComplianceMessages", null)
      notScopes             = lookup(each.value.assignment.properties, "notScopes", null)
      overrides             = lookup(each.value.assignment.properties, "overrides", null)
      parameters            = lookup(each.value.assignment.properties, "parameters", null)
      policyDefinitionId    = lookup(each.value.assignment.properties, "policyDefinitionId", null)
      resourceSelectors     = lookup(each.value.assignment.properties, "resourceSelectors", null)
    }
  }
  create_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property = true
  read_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    lookup(each.value.assignment.properties, "policyDefinitionId", null),
    var.location,
  ]
  retry = var.retries.policy_assignments.error_message_regex != null ? {
    error_message_regex  = var.retries.policy_assignments.error_message_regex
    interval_seconds     = lookup(var.retries.policy_assignments, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.policy_assignments, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.policy_assignments, "multiplier", null)
    randomization_factor = lookup(var.retries.policy_assignments, "randomization_factor", null)
  } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = lookup(each.value.assignment, "identity", null) != null ? [each.value.assignment.identity] : []

    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }
  timeouts {
    create = var.timeouts.policy_assignment.create
    delete = var.timeouts.policy_assignment.delete
    read   = var.timeouts.policy_assignment.read
    update = var.timeouts.policy_assignment.update
  }

  depends_on = [
    time_sleep.after_policy_set_definitions,
    terraform_data.policy_assignments_dependencies,
  ]

  lifecycle {
    ignore_changes = [
      body.properties.metadata.createdBy,
      body.properties.metadata.createdOn,
      body.properties.metadata.updatedBy,
      body.properties.metadata.updatedOn,
    ]
  }
}
