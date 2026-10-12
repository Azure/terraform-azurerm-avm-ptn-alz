data "alz_architecture" "this" {
  name                                                          = var.architecture_name
  root_management_group_id                                      = var.parent_resource_id
  location                                                      = var.location
  policy_assignments_to_modify                                  = var.policy_assignments_to_modify
  policy_default_values                                         = var.policy_default_values
  default_non_compliance_message_settings                       = var.policy_assignment_non_compliance_message_settings
  override_policy_definition_parameter_assign_permissions_set   = var.override_policy_definition_parameter_assign_permissions_set
  override_policy_definition_parameter_assign_permissions_unset = var.override_policy_definition_parameter_assign_permissions_unset
}

check "telemetry_additional_content_deprecated" {
  assert {
    condition     = var.telemetry_additional_content == null ? true : length(var.telemetry_additional_content) == 0
    error_message = "telemetry_additional_content is deprecated and ignored. Custom telemetry content is no longer collected; remove this input."
  }
}
