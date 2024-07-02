output "management_group_resource_ids" {
  value = { for k, v in merge(
    module.management_groups_level_0,
    module.management_groups_level_1,
    module.management_groups_level_2,
    module.management_groups_level_3,
    module.management_groups_level_4,
    module.management_groups_level_5,
    module.management_groups_level_6,
  ) : k => v.id }
}

output "policy_assignment_resource_ids" {
  value = { for k, v in module.policy_assignment : k => v.id }
}

output "policy_definition_resource_ids" {
  value = { for k, v in module.policy_definitions : k => v.id }
}

output "policy_role_assignment_resource_ids" {
  value = { for k, v in module.policy_role_assignments : k => v.id }
}

output "policy_set_definition_resource_ids" {
  value = { for k, v in module.policy_set_definitions : k => v.id }
}
