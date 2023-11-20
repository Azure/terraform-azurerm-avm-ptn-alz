locals {
  location                = "westus2"
  management_group_config = yamldecode(file("${path.root}/managementgroups.yaml"))

  management_groups_layer_1 = { for k, v in local.management_group_config : k => v if v.parent == "base" }
  management_groups_layer_2 = { for k, v in local.management_group_config : k => v if contains(values(local.management_groups_layer_1)[*].id, v.parent) }
  management_groups_layer_3 = { for k, v in local.management_group_config : k => v if contains(values(local.management_groups_layer_2)[*].id, v.parent) }
  management_groups_layer_4 = { for k, v in local.management_group_config : k => v if contains(values(local.management_groups_layer_3)[*].id, v.parent) }
  management_groups_layer_5 = { for k, v in local.management_group_config : k => v if contains(values(local.management_groups_layer_4)[*].id, v.parent) }
  management_groups_layer_6 = { for k, v in local.management_group_config : k => v if contains(values(local.management_groups_layer_5)[*].id, v.parent) }
}

output "test" {
  value = {
    management_groups_layer_1 = local.management_groups_layer_1
    management_groups_layer_2 = local.management_groups_layer_2
    management_groups_layer_3 = local.management_groups_layer_3
    management_groups_layer_4 = local.management_groups_layer_4
    management_groups_layer_5 = local.management_groups_layer_5
    management_groups_layer_6 = local.management_groups_layer_6
  }
}