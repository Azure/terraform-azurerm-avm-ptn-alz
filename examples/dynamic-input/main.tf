data "azurerm_client_config" "current" {}

module "management_groups_layer_1" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_1
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = data.azurerm_client_config.current.tenant_id
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
}

module "management_groups_layer_2" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_2
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = each.value.parent
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
  depends_on       = [module.management_groups_layer_1]
}

module "management_groups_layer_3" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_3
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = each.value.parent
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
  depends_on       = [module.management_groups_layer_2]
}

module "management_groups_layer_4" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_4
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = each.value.parent
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
  depends_on       = [module.management_groups_layer_3]
}

module "management_groups_layer_5" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_5
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = each.value.parent
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
  depends_on       = [module.management_groups_layer_4]
}

module "management_groups_layer_6" {
  source = "../../"
  #version                            = "~> 0.4.1"
  for_each         = local.management_groups_layer_6
  id               = each.value.id
  display_name     = try(each.value.display_name, each.value.id)
  parent_id        = each.value.parent
  base_archetype   = each.value.base_archetype
  default_location = local.location
  #default_log_analytics_workspace_id = module.management_resources.log_analytics_workspace.id
  subscription_ids = try(each.value.subscription_ids, [])
  depends_on       = [module.management_groups_layer_5]
}
