# # This helps keep naming unique
# resource "random_pet" "this" {
#   length = 1
# }

# module "naming" {
#   source  = "Azure/naming/azurerm"
#   version = "~> 0.3"
#   suffix  = [random_pet.this.id]
#   prefix  = ["test-avm-ptn-alz"]
# }

# module "alz_management_resources" {
#   source  = "Azure/alz-management/azurerm"
#   version = "~> 0.1"

#   automation_account_name      = module.naming.automation_account.name
#   location                     = local.default_location
#   log_analytics_workspace_name = module.naming.log_analytics_workspace.name
#   resource_group_name          = module.naming.resource_group.name
# }

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

module "alz_architecture" {
  source             = "../../"
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = "uksouth"
}

# module "alz_archetype_landing_zones" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-landing-zones"
#   display_name                       = "${random_pet.this.id}-landing-zones"
#   parent_resource_id                 = module.alz_archetype_root.management_group_resource_id
#   base_archetype                     = "landing_zones"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_platform" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-platform"
#   display_name                       = "${random_pet.this.id}-platform"
#   parent_resource_id                 = module.alz_archetype_root.management_group_resource_id
#   base_archetype                     = "platform"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_identity" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-identity"
#   display_name                       = "${random_pet.this.id}-identity"
#   parent_resource_id                 = module.alz_archetype_platform.management_group_resource_id
#   base_archetype                     = "identity"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_connectivity" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-connectivity"
#   display_name                       = "${random_pet.this.id}-connectivity"
#   parent_resource_id                 = module.alz_archetype_platform.management_group_resource_id
#   base_archetype                     = "connectivity"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_management" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-management"
#   display_name                       = "${random_pet.this.id}-management"
#   parent_resource_id                 = module.alz_archetype_platform.management_group_resource_id
#   base_archetype                     = "management"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   subscription_ids                   = [data.azurerm_client_config.current.subscription_id]
#   delays                             = local.default_delays
# }

# module "alz_archetype_corp" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-corp"
#   display_name                       = "${random_pet.this.id}-corp"
#   parent_resource_id                 = module.alz_archetype_landing_zones.management_group_resource_id
#   base_archetype                     = "corp"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_online" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-online"
#   display_name                       = "${random_pet.this.id}-online"
#   parent_resource_id                 = module.alz_archetype_landing_zones.management_group_resource_id
#   base_archetype                     = "online"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }

# module "alz_archetype_sandboxes" {
#   source                             = "../../"
#   id                                 = "${random_pet.this.id}-sandboxes"
#   display_name                       = "${random_pet.this.id}-sandboxes"
#   parent_resource_id                 = module.alz_archetype_root.management_group_resource_id
#   base_archetype                     = "sandboxes"
#   default_location                   = local.default_location
#   default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
#   delays                             = local.default_delays
# }
