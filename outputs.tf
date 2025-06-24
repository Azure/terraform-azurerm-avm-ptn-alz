output "management_group_resource_ids" {
  description = "A map of management group names to their resource ids."
  value       = local.management_group_key_to_resource_id
}

output "policy_assignment_identity_ids" {
  description = "A map of policy assignment names to their identity ids."
  value       = { for k, v in local.policy_assignment_identities : k => v.principal_id if v != null }
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
