# This helps keep naming unique
resource "random_pet" "this" {
  length = 1
}

module "naming" {
  source = "Azure/naming/azurerm"
  suffix = [random_pet.this.id]
}

module "alz_management_resources" {
  source  = "Azure/alz-management/azurerm"
  version = "~> 0.1.0"

  automation_account_name      = module.naming.automation_account.name
  location                     = local.location
  log_analytics_workspace_name = module.naming.log_analytics_workspace.name
  resource_group_name          = module.naming.resource_group.name
}

data "azurerm_client_config" "current" {}

module "management_groups_layer_1" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_1
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = data.azurerm_client_config.current.tenant_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}

module "management_groups_layer_2" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_2
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = module.management_groups_layer_1[each.value.parent].management_group_name
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}

module "management_groups_layer_3" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_3
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = module.management_groups_layer_2[each.value.parent].management_group_name
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}

module "management_groups_layer_4" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_4
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = module.management_groups_layer_3[each.value.parent].management_group_name
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}

module "management_groups_layer_5" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_5
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = module.management_groups_layer_4[each.value.parent].management_group_name
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}

module "management_groups_layer_6" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_6
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_id                          = module.management_groups_layer_5[each.value.parent].management_group_name
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
}
