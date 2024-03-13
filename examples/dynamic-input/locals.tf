locals {
  default_delays = {
    before_management_group_creation = {
      create = "30s"
    }
    before_policy_assignments = {
      create  = "300s"
      destroy = "120s"
    }
    before_policy_role_assignments = {
      create  = "60s"
      destroy = "60s"
    }
  }
  location                  = "uksouth"
  management_group_config   = yamldecode(file("${path.root}/managementgroups.yaml"))
  management_groups_layer_1 = { for k, v in local.management_group_config : k => v if v.parent == "base" }
  management_groups_layer_2 = { for k, v in local.management_group_config : k => v if contains(keys(local.management_groups_layer_1), v.parent) }
  management_groups_layer_3 = { for k, v in local.management_group_config : k => v if contains(keys(local.management_groups_layer_2), v.parent) }
  management_groups_layer_4 = { for k, v in local.management_group_config : k => v if contains(keys(local.management_groups_layer_3), v.parent) }
  management_groups_layer_5 = { for k, v in local.management_group_config : k => v if contains(keys(local.management_groups_layer_4), v.parent) }
  management_groups_layer_6 = { for k, v in local.management_group_config : k => v if contains(keys(local.management_groups_layer_5), v.parent) }
}
