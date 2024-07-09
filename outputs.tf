output "management_group_resource_ids" {
  value = { for k, v in merge(
    module.management_groups_level_0,
    module.management_groups_level_1,
    module.management_groups_level_2,
    module.management_groups_level_3,
    module.management_groups_level_4,
    module.management_groups_level_5,
    module.management_groups_level_6,
  ) : k => v.resource_id }
}

output "policy_assignment_identity_ids" {
  description = "A map of policy assignment names to their identity ids."
  value       = { for k, v in module.policy_assignment : k => v.identity.principal_id if v.identity != null }
}

output "policy_assignment_resource_ids" {
  description = "A map of policy assignment names to their resource ids."
  value       = { for k, v in module.policy_assignment : k => v.resource_id }
}

output "policy_definition_resource_ids" {
  description = "A map of policy definition names to their resource ids."
  value       = { for k, v in module.policy_definitions : k => v.resource_id }
}

output "policy_role_assignment_resource_ids" {
  description = "A map of policy role assignments to their resource ids."
  value       = { for k, v in module.policy_role_assignments : k => v.resource_id }
}

output "policy_set_definition_resource_ids" {
  description = "A map of policy set definition names to their resource ids."
  value       = { for k, v in module.policy_set_definitions : k => v.resource_id }
}

output "role_definition_resource_ids" {
  description = "A map of role definition names to their resource ids."
  value       = { for k, v in module.role_definitions : k => v.resource_id }
}
