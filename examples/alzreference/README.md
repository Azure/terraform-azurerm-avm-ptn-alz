<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.

```hcl
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

module "alz_root" {
  source                             = "../../"
  id                                 = "alz-root"
  display_name                       = "alz-root"
  parent_id                          = data.azurerm_client_config.current.tenant_id
  base_archetype                     = "root"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_landing_zones" {
  source                             = "../../"
  id                                 = "landing-zones"
  display_name                       = "landing-zones"
  parent_id                          = module.alz_root.management_group_name
  base_archetype                     = "landing_zones"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_platform" {
  source                             = "../../"
  id                                 = "platform"
  display_name                       = "platform"
  parent_id                          = module.alz_root.management_group_name
  base_archetype                     = "platform"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_identity" {
  source                             = "../../"
  id                                 = "identity"
  display_name                       = "identity"
  parent_id                          = module.alz_platform.management_group_name
  base_archetype                     = "identity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_connectivity" {
  source                             = "../../"
  id                                 = "connectivity"
  display_name                       = "connectivity"
  parent_id                          = module.alz_platform.management_group_name
  base_archetype                     = "connectivity"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_mgmt" {
  source                             = "../../"
  id                                 = "management"
  display_name                       = "management"
  parent_id                          = module.alz_platform.management_group_name
  base_archetype                     = "management"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_corp" {
  source                             = "../../"
  id                                 = "corp"
  display_name                       = "corp"
  parent_id                          = module.alz_landing_zones.management_group_name
  base_archetype                     = "corp"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_online" {
  source                             = "../../"
  id                                 = "online"
  display_name                       = "online"
  parent_id                          = module.alz_landing_zones.management_group_name
  base_archetype                     = "management"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}

module "alz_sandboxes" {
  source                             = "../../"
  id                                 = "sandboxes"
  display_name                       = "sandboxes"
  parent_id                          = module.alz_root.management_group_name
  base_archetype                     = "sandboxes"
  default_location                   = local.default_location
  default_log_analytics_workspace_id = module.alz_management.log_analytics_workspace.id
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)

- <a name="provider_random"></a> [random](#provider\_random)

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

### <a name="module_alz_connectivity"></a> [alz\_connectivity](#module\_alz\_connectivity)

Source: ../../

Version:

### <a name="module_alz_corp"></a> [alz\_corp](#module\_alz\_corp)

Source: ../../

Version:

### <a name="module_alz_identity"></a> [alz\_identity](#module\_alz\_identity)

Source: ../../

Version:

### <a name="module_alz_landing_zones"></a> [alz\_landing\_zones](#module\_alz\_landing\_zones)

Source: ../../

Version:

### <a name="module_alz_management"></a> [alz\_management](#module\_alz\_management)

Source: Azure/alz-management/azurerm

Version: ~> 0.1.0

### <a name="module_alz_mgmt"></a> [alz\_mgmt](#module\_alz\_mgmt)

Source: ../../

Version:

### <a name="module_alz_online"></a> [alz\_online](#module\_alz\_online)

Source: ../../

Version:

### <a name="module_alz_platform"></a> [alz\_platform](#module\_alz\_platform)

Source: ../../

Version:

### <a name="module_alz_root"></a> [alz\_root](#module\_alz\_root)

Source: ../../

Version:

### <a name="module_alz_sandboxes"></a> [alz\_sandboxes](#module\_alz\_sandboxes)

Source: ../../

Version:


<!-- END_TF_DOCS -->