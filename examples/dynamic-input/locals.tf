locals {
  location                = "westus2"
  management_group_config = yamldecode(file("${path.root}/managementgroups.yaml"))

  management_groups_layer_1 = { for k, v in local.management_group_config : k => v if v.parent == null }
  management_groups_layer_2 = { for k, v in local.management_group_config : k => v if try(contains(local.management_groups_layer_1, v.parent), false) }
  management_groups_layer_3 = { for k, v in local.management_group_config : k => v if try(contains(local.management_groups_layer_2, v.parent), false) }
  management_groups_layer_4 = { for k, v in local.management_group_config : k => v if try(contains(local.management_groups_layer_3, v.parent), false) }
  management_groups_layer_5 = { for k, v in local.management_group_config : k => v if try(contains(local.management_groups_layer_4, v.parent), false) }
  management_groups_layer_6 = { for k, v in local.management_group_config : k => v if try(contains(local.management_groups_layer_5, v.parent), false) }
}
