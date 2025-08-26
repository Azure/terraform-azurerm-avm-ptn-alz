output "management_group_resource_ids" {
  description = "A map of management group names to their resource ids."
  value = { for k, v in merge(
    azapi_resource.management_groups_level_0,
    azapi_resource.management_groups_level_1,
    azapi_resource.management_groups_level_2,
    azapi_resource.management_groups_level_3,
    azapi_resource.management_groups_level_4,
    azapi_resource.management_groups_level_5,
    azapi_resource.management_groups_level_6,
  ) : k => v.id }
}

output "policy_assignment_identity_ids" {
  description = "A map of policy assignment names to their identity ids."
  value       = { for k, v in local.policy_assignment_identities : k => v if v != null }
}

output "policy_assignment_resource_ids" {
  description = "A map of policy assignment names to their resource ids."
  value       = { for k, v in azapi_resource.policy_assignments : k => v.id }
}

output "policy_definition_resource_ids" {
  description = "A map of policy definition names to their resource ids."
  value       = { for k, v in azapi_resource.policy_definitions : k => v.id }
}

output "policy_role_assignment_resource_ids" {
  description = "A map of policy role assignments to their resource ids."
  value       = { for k, v in azapi_resource.policy_role_assignments : k => v.id }
}

output "policy_set_definition_resource_ids" {
  description = "A map of policy set definition names to their resource ids."
  value       = { for k, v in azapi_resource.policy_set_definitions : k => v.id }
}

output "role_definition_resource_ids" {
  description = "A map of role definition names to their resource ids."
  value       = { for k, v in azapi_resource.role_definitions : k => v.id }
}
