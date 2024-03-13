<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture with a Dynamic Configuration File

This example shows how to deploy the ALZ reference architecture from a dynamic YAML configuration file.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.
It then uses a YAML file to define the hierarchy.

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
  parent_resource_id                 = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays = merge(local.default_delays, {
    before_management_group_creation = {
      create = "0s"
    }
  })
}

module "management_groups_layer_2" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_2
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_resource_id                 = module.management_groups_layer_1[each.value.parent].management_group_resource_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays                             = local.default_delays
}

module "management_groups_layer_3" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_3
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_resource_id                 = module.management_groups_layer_2[each.value.parent].management_group_resource_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays                             = local.default_delays
}

module "management_groups_layer_4" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_4
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_resource_id                 = module.management_groups_layer_3[each.value.parent].management_group_resource_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays                             = local.default_delays
}

module "management_groups_layer_5" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_5
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_resource_id                 = module.management_groups_layer_4[each.value.parent].management_group_resource_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays                             = local.default_delays
}

module "management_groups_layer_6" {
  source                             = "../../"
  for_each                           = local.management_groups_layer_6
  id                                 = "${each.value.id}-${random_pet.this.id}"
  display_name                       = try(each.value.display_name, each.value.id)
  parent_resource_id                 = module.management_groups_layer_5[each.value.parent].management_group_resource_id
  base_archetype                     = each.value.base_archetype
  default_location                   = local.location
  default_log_analytics_workspace_id = module.alz_management_resources.log_analytics_workspace.id
  subscription_ids                   = try(each.value.subscription_ids, [])
  delays                             = local.default_delays
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (>= 0.6.3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.74.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.74.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

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

The following outputs are exported:

### <a name="output_test"></a> [test](#output\_test)

Description: An object containing the management groups for each layer.

## Modules

The following Modules are called:

### <a name="module_alz_management_resources"></a> [alz\_management\_resources](#module\_alz\_management\_resources)

Source: Azure/alz-management/azurerm

Version: ~> 0.1

### <a name="module_management_groups_layer_1"></a> [management\_groups\_layer\_1](#module\_management\_groups\_layer\_1)

Source: ../../

Version:

### <a name="module_management_groups_layer_2"></a> [management\_groups\_layer\_2](#module\_management\_groups\_layer\_2)

Source: ../../

Version:

### <a name="module_management_groups_layer_3"></a> [management\_groups\_layer\_3](#module\_management\_groups\_layer\_3)

Source: ../../

Version:

### <a name="module_management_groups_layer_4"></a> [management\_groups\_layer\_4](#module\_management\_groups\_layer\_4)

Source: ../../

Version:

### <a name="module_management_groups_layer_5"></a> [management\_groups\_layer\_5](#module\_management\_groups\_layer\_5)

Source: ../../

Version:

### <a name="module_management_groups_layer_6"></a> [management\_groups\_layer\_6](#module\_management\_groups\_layer\_6)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

<!-- END_TF_DOCS -->