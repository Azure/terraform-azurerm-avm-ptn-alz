data "alz_architecture" "this" {
  name                         = var.architecture_name
  root_management_group_id     = var.parent_resource_id
  location                     = var.location
  policy_assignments_to_modify = var.policy_assignments_to_modify
  policy_default_values        = var.policy_default_values

  override_policy_definition_parameter_assign_permissions_set   = var.override_policy_definition_parameter_assign_permissions_set
  override_policy_definition_parameter_assign_permissions_unset = var.override_policy_definition_parameter_assign_permissions_unset
}
