resource "time_sleep" "after_management_groups" {
  create_duration  = var.delays.after_management_group.create
  destroy_duration = var.delays.after_management_group.destroy
  triggers = {
    management_groups = sha256(jsonencode(local.management_groups))
  }

  depends_on = [
    module.management_groups_level_0,
    module.management_groups_level_1,
    module.management_groups_level_2,
    module.management_groups_level_3,
    module.management_groups_level_4,
    module.management_groups_level_5,
    module.management_groups_level_6,
  ]
}

resource "time_sleep" "after_policy_definitions" {
  create_duration  = var.delays.after_policy_definitions.create
  destroy_duration = var.delays.after_policy_definitions.destroy
  triggers = {
    policy_definitions = sha256(jsonencode(local.policy_definitions))
  }

  depends_on = [
    module.policy_definitions
  ]
}

resource "time_sleep" "after_policy_set_definitions" {
  create_duration  = var.delays.after_policy_set_definitions.create
  destroy_duration = var.delays.after_policy_set_definitions.destroy
  triggers = {
    policy_definitions = sha256(jsonencode(local.policy_set_definitions))
  }

  depends_on = [
    module.policy_set_definitions
  ]
}
