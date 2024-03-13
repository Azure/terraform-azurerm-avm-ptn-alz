<!-- BEGIN_TF_DOCS -->
# Policy Assignment Modification with Custom Lib

This example demonstrates some common patterns:

- Deploying a custom management group hierarchy
- The use of a custom library, with an archetype override and additional policy assignment
- Modification of a policy assignment to supply new parameters to an assigned policy

Thanks to [@phx-tim-butters](https://github.com/phx-tim-butters) for this example

```hcl
terraform {
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.11"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Include the additional policies and override archetypes
provider "alz" {
  lib_urls = ["${path.root}/lib"]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "update_manager" {
  name     = "rg_test"
  location = "uksouth"
}

resource "azurerm_maintenance_configuration" "this" {
  name                = "ring1"
  resource_group_name = azurerm_resource_group.update_manager.name
  location            = azurerm_resource_group.update_manager.location
  scope               = "InGuestPatch"

  window {
    start_date_time = "2024-01-03 00:00"
    duration        = "03:55"
    time_zone       = "GMT Standard Time"
    recur_every     = "Week"
  }

  install_patches {
    windows {
      classifications_to_include = ["Critical", "Security", "Definition"]
    }
    reboot = "IfRequired"
  }
}

module "alz_archetype_root" {
  source             = "../../"
  id                 = "root"
  display_name       = "root"
  parent_resource_id = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
  base_archetype     = "root_override"
  default_location   = "uksouth"
  policy_assignments_to_modify = {
    Update-Ring1 = {
      parameters = jsonencode({
        maintenanceConfigurationResourceId = azurerm_maintenance_configuration.this.id
      })
    }
  }
}

module "alz_archetype_platform" {
  source             = "../../"
  id                 = "plat"
  display_name       = "plat"
  parent_resource_id = module.alz_archetype_root.management_group_resource_id
  base_archetype     = "platform"
  default_location   = "uksouth"
}

module "alz_archetype_landing_zones" {
  source             = "../../"
  id                 = "landing_zones"
  display_name       = "landing_zones"
  parent_resource_id = module.alz_archetype_root.management_group_resource_id
  base_archetype     = "landing_zones"
  default_location   = "uksouth"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.11)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.74.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.74.0)

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

### <a name="module_alz_archetype_landing_zones"></a> [alz\_archetype\_landing\_zones](#module\_alz\_archetype\_landing\_zones)

Source: ../../

Version:

### <a name="module_alz_archetype_platform"></a> [alz\_archetype\_platform](#module\_alz\_archetype\_platform)

Source: ../../

Version:

### <a name="module_alz_archetype_root"></a> [alz\_archetype\_root](#module\_alz\_archetype\_root)

Source: ../../

Version:

<!-- END_TF_DOCS -->