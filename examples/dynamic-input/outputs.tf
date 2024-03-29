output "test" {
  description = "An object containing the management groups for each layer."
  value = {
    management_groups_layer_1 = local.management_groups_layer_1
    management_groups_layer_2 = local.management_groups_layer_2
    management_groups_layer_3 = local.management_groups_layer_3
    management_groups_layer_4 = local.management_groups_layer_4
    management_groups_layer_5 = local.management_groups_layer_5
    management_groups_layer_6 = local.management_groups_layer_6
  }
}
