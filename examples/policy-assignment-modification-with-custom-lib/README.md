<!-- BEGIN_TF_DOCS -->
# Policy Assignment Modification with Custom Lib

This example demonstrates some common patterns:

- Deploying a custom management group hierarchy defined by an architecture definition file in the local library
- The use of a custom library, with an archetype override and additional policy assignment
- Modification of a policy assignment to supply new parameters to an assigned policy

Thanks to [@phx-tim-butters](https://github.com/phx-tim-butters) for this example!

```hcl
# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      ref  = "2024.10.1"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "update_manager" {
  location = local.location
  name     = local.update_manager_rg_name
}

resource "azurerm_maintenance_configuration" "this" {
  location                 = azurerm_resource_group.update_manager.location
  name                     = local.maintenance_configuration_name
  resource_group_name      = azurerm_resource_group.update_manager.name
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  install_patches {
    reboot = "IfRequired"

    windows {
      classifications_to_include = ["Critical", "Security", "Definition"]
    }
  }
  window {
    start_date_time = "2024-01-03 00:00"
    time_zone       = "GMT Standard Time"
    duration        = "03:55"
    recur_every     = "Week"
  }
}

# The provider shouldn't have any unknown values passed in, or it will mark
# all resources as needing replacement.
locals {
  location                              = "swedencentral"
  maintenance_configuration_name        = "ring1"
  maintenance_configuration_resource_id = provider::azapi::resource_group_resource_id(data.azurerm_client_config.current.subscription_id, local.update_manager_rg_name, "Microsoft.Maintenance/maintenanceConfigurations", [local.maintenance_configuration_name])
  update_manager_rg_name                = "rg-update-manager"
}

module "alz" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = local.location
  policy_assignments_to_modify = {
    myroot = {
      policy_assignments = {
        Update-Ring1 = {
          parameters = {
            maintenanceConfigurationResourceId = jsonencode({ value = local.maintenance_configuration_resource_id })
          }
        }
      }
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.16)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_maintenance_configuration.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/maintenance_configuration) (resource)
- [azurerm_resource_group.update_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
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

### <a name="module_alz"></a> [alz](#module\_alz)

Source: ../../

Version:

<!-- END_TF_DOCS -->