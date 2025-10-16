module "avm_interfaces" {
  source   = "Azure/avm-utl-interfaces/azure"
  version  = "0.5.0"
  for_each = var.management_group_role_assignments

  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = var.role_assignment_definition_lookup_enabled
  role_assignment_definition_scope          = provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [each.value.management_group_name])
  role_assignment_name_use_random_uuid      = var.role_assignment_name_use_random_uuid
  role_assignments = {
    this = {
      role_definition_id_or_name             = each.value.role_definition_id_or_name
      principal_id                           = each.value.principal_id
      description                            = each.value.description
      skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
      condition                              = each.value.condition
      condition_version                      = each.value.condition_version
      delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
      principal_type                         = each.value.principal_type
    }
  }

  depends_on = [azapi_resource.role_definitions]
}

resource "azapi_resource" "management_group_role_assignments" {
  for_each = module.avm_interfaces

  name                   = each.value.role_assignments_azapi.this.name
  parent_id              = provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [var.management_group_role_assignments[each.key].management_group_name])
  type                   = "Microsoft.Authorization/roleAssignments@${var.resource_api_versions.role_assignment}"
  body                   = each.value.role_assignments_azapi.this.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry = {
    error_message_regex  = var.retries.role_assignments.error_message_regex
    interval_seconds     = var.retries.role_assignments.interval_seconds
    max_interval_seconds = var.retries.role_assignments.max_interval_seconds
    multiplier           = var.retries.role_assignments.multiplier
    randomization_factor = var.retries.role_assignments.randomization_factor
  }
  schema_validation_enabled = var.schema_validation_enabled.role_assignments
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.role_assignment.create
    delete = var.timeouts.role_assignment.delete
    read   = var.timeouts.role_assignment.read
    update = var.timeouts.role_assignment.update
  }

  depends_on = [
    azapi_resource.role_definitions,
  ]
}
