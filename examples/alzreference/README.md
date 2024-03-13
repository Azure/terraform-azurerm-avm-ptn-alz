<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.

```hcl
# This helps keep naming unique
resource "random_pet" "this" {
  length = 1
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = [random_pet.this.id]
  prefix  = ["test-avm-ptn-alz"]
}

module "alz_management_resources" {
  source  = "Azure/alz-management/azurerm"
  version = "~> 0.1"

  automation_account_name      = module.naming.automation_account.name
  location                     = local.default_location
  log_analytics_workspace_name = module.naming.log_analytics_workspace.name
  resource_group_name          = module.naming.resource_group.name
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
  delays = merge(local.default_delays, {
    before_management_group_creation = {
      create = "0s"
    }
  })
  policy_assignments_to_modify = {
    Deny-UnmanagedDisk = {
      resource_selectors = [{
        name = "only-uk"
        selectors = [{
          kind = "resourceLocation"
          in   = ["uksouth", "ukwest"]
        }]
      }]
    }
  }
}

module "alz_archetype_landing_zones" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-landing-zones"
  display_name                       = "${random_pet.this.id}-landing-zones"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "landing_zones_override"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_platform" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-platform"
  display_name                       = "${random_pet.this.id}-platform"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "platform_override"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_identity" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-identity"
  display_name                       = "${random_pet.this.id}-identity"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "identity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_connectivity" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-connectivity"
  display_name                       = "${random_pet.this.id}-connectivity"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "connectivity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_management" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-management"
  display_name                       = "${random_pet.this.id}-management"
  parent_id                          = module.alz_archetype_platform.management_group_name
  base_archetype                     = "management"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = [data.azurerm_client_config.current.subscription_id]
  delays                             = local.default_delays
}

module "alz_archetype_corp" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-corp"
  display_name                       = "${random_pet.this.id}-corp"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "corp"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_online" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-online"
  display_name                       = "${random_pet.this.id}-online"
  parent_id                          = module.alz_archetype_landing_zones.management_group_name
  base_archetype                     = "online"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}

module "alz_archetype_sandboxes" {
  source                             = "../../"
  id                                 = "${random_pet.this.id}-sandboxes"
  display_name                       = "${random_pet.this.id}-sandboxes"
  parent_id                          = module.alz_archetype_root.management_group_name
  base_archetype                     = "sandboxes"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  delays                             = local.default_delays
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.10)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.74)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz_archetype_connectivity"></a> [alz\_archetype\_connectivity](#module\_alz\_archetype\_connectivity)

Source: ../../

Version:

### <a name="module_alz_archetype_corp"></a> [alz\_archetype\_corp](#module\_alz\_archetype\_corp)

Source: ../../

Version:

### <a name="module_alz_archetype_identity"></a> [alz\_archetype\_identity](#module\_alz\_archetype\_identity)

Source: ../../

Version:

### <a name="module_alz_archetype_landing_zones"></a> [alz\_archetype\_landing\_zones](#module\_alz\_archetype\_landing\_zones)

Source: ../../

Version:

### <a name="module_alz_archetype_management"></a> [alz\_archetype\_management](#module\_alz\_archetype\_management)

Source: ../../

Version:

### <a name="module_alz_archetype_online"></a> [alz\_archetype\_online](#module\_alz\_archetype\_online)

Source: ../../

Version:

### <a name="module_alz_archetype_platform"></a> [alz\_archetype\_platform](#module\_alz\_archetype\_platform)

Source: ../../

Version:

### <a name="module_alz_archetype_root"></a> [alz\_archetype\_root](#module\_alz\_archetype\_root)

Source: ../../

Version:

### <a name="module_alz_archetype_sandboxes"></a> [alz\_archetype\_sandboxes](#module\_alz\_archetype\_sandboxes)

Source: ../../

Version:

### <a name="module_alz_management_resources"></a> [alz\_management\_resources](#module\_alz\_management\_resources)

Source: Azure/alz-management/azurerm

Version: ~> 0.1

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

<!-- END_TF_DOCS -->