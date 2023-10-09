# This helps keep naming unique
resource "random_pet" "this" {
  length = 1
}

module "naming" {
  source = "Azure/naming/azurerm"
}

module "alz_management_resources" {
  source  = "Azure/alz-management/azurerm"
  version = "~> 0.1.0"

  automation_account_name      = module.naming.automation_account.name_unique
  location                     = local.default_location
  log_analytics_workspace_name = module.naming.log_analytics_workspace.name_unique
  resource_group_name          = module.naming.resource_group.name_unique
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

module "alz_archetype_root" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-alz-root"
  display_name                       = "${random_pet.this.id}-alz-root"
  parent_id                          = data.azurerm_client_config.current.tenant_id
  base_archetype                     = "root"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays = {
    before_management_group_creation = {
      create = "0s"
    }
  }
}

module "alz_archetype_landing_zones" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-landing-zones"
  display_name                       = "${random_pet.this.id}-landing-zones"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "landing_zones"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_platform" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-platform"
  display_name                       = "${random_pet.this.id}-platform"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "platform"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_identity" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-identity"
  display_name                       = "${random_pet.this.id}-identity"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "identity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_connectivity" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-connectivity"
  display_name                       = "${random_pet.this.id}-connectivity"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "connectivity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_management" {
  source                             = "../../"
  id                                 = "management"
  display_name                       = "management"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "management"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_corp" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-corp"
  display_name                       = "${random_pet.this.id}-corp"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "corp"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_online" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-online"
  display_name                       = "${random_pet.this.id}-online"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "online"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}

module "alz_archetype_sandboxes" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-sandboxes"
  display_name                       = "${random_pet.this.id}-sandboxes"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "sandboxes"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
}
