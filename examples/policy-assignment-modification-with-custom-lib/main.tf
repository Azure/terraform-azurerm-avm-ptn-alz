# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      ref  = "2024.07.02"
    },
    {
      custom_url = "${path.cwd}/lib"
    }
  ]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "update_manager" {
  location = "northeurope"
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
  maintenance_configuration_name        = "ring1"
  maintenance_configuration_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.update_manager_rg_name}/providers/Microsoft.Maintenance/maintenanceConfigurations/${local.maintenance_configuration_name}"
  update_manager_rg_name                = "rg-update-manager"
}

module "alz" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = "northeurope"
  policy_assignments_to_modify = {
    myroot = {
      policy_assignments = {
        Update-Ring1 = {
          parameters = jsonencode({
            maintenanceConfigurationResourceId = local.maintenance_configuration_resource_id
          })
        }
      }
    }
  }
}
