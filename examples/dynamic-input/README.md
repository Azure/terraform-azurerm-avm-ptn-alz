<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture with a Dynamic Configuration File

This example shows how to deploy the ALZ reference architecture from a dynamic YAML configuration file.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.
It then uses a YAML file to define the hierarchy.

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 2.79.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.1)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 2.79.0)

## Resources

The following resources are used by this module:

- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_test"></a> [test](#output\_test)

Description: n/a

## Modules

The following Modules are called:

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


<!-- END_TF_DOCS -->