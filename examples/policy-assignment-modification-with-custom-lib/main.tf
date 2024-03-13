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
