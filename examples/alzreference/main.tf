# This helps keep naming unique
resource "random_pet" "this" {}

module "alz_management" {
  source  = "Azure/alz-management/azurerm"
  version = "~> 0.1.0"

  automation_account_name      = "aa-${random_pet.this.id}"
  location                     = local.default_location
  log_analytics_workspace_name = "law-${random_pet.this.id}"
  resource_group_name          = "rg-${random_pet.this.id}"
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

module "alz_archetype_root" {
  source                                = "../../"
  id                                    = "alz-root-${random_pet.this.id}"
  display_name                          = "alz-roo-${random_pet.this.id}"
  parent_id                             = data.azurerm_client_config.current.tenant_id
  base_archetype                        = "root"
  default_location                      = local.default_location
  default_log_analytics_workspace_id    = module.alz_management.log_analytics_workspace.id
  wait_before_management_group_creation = "0s"
}

module "alz_archetype_landing_zones" {
  source                             = "../../"
  id                                 = "landing-zones-${random_pet.this.id}"
  display_name                       = "landing-zones-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "landing_zones"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_platform" {
  source                             = "../../"
  id                                 = "platform-${random_pet.this.id}"
  display_name                       = "platform-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "platform"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_identity" {
  source                             = "../../"
  id                                 = "identity-${random_pet.this.id}"
  display_name                       = "identity-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "identity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_connectivity" {
  source                             = "../../"
  id                                 = "connectivity-${random_pet.this.id}"
  display_name                       = "connectivity-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "connectivity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_mgmt" {
  source                             = "../../"
  id                                 = "management-${random_pet.this.id}"
  display_name                       = "management-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "management"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_corp" {
  source                             = "../../"
  id                                 = "corp-${random_pet.this.id}"
  display_name                       = "corp-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "corp"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_online" {
  source                             = "../../"
  id                                 = "online-${random_pet.this.id}"
  display_name                       = "online-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "online"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_archetype_sandboxes" {
  source                             = "../../"
  id                                 = "sandboxes-${random_pet.this.id}"
  display_name                       = "sandboxes-${random_pet.this.id}"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "sandboxes-${random_pet.this.id}"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}
