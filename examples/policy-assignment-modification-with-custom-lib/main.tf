# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      "path" : "platform/alz",
      "ref" : "2025.02.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = local.resource_group_name
}

resource "azurerm_maintenance_configuration" "this" {
  location                 = azurerm_resource_group.this.location
  name                     = local.maintenance_configuration_name
  resource_group_name      = azurerm_resource_group.this.name
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

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.user_assigned_identity_name
  resource_group_name = azurerm_resource_group.this.name
}

# The provider shouldn't have any unknown values passed in, or it will mark
# all resources as needing replacement.
locals {
  location                              = "swedencentral"
  maintenance_configuration_name        = "ring1"
  maintenance_configuration_resource_id = provider::azapi::resource_group_resource_id(data.azurerm_client_config.current.subscription_id, local.resource_group_name, "Microsoft.Maintenance/maintenanceConfigurations", [local.maintenance_configuration_name])
  resource_group_name                   = "rg-update-manager"
  user_assigned_identity_name           = "uami-policy"
  user_assigned_identity_resource_id    = provider::azapi::resource_group_resource_id(data.azurerm_client_config.current.subscription_id, local.resource_group_name, "Microsoft.ManagedIdentity/userAssignedIdentities", [local.user_assigned_identity_name])
}

module "alz" {
  source = "../../"

  architecture_name  = "custom"
  location           = local.location
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  policy_assignments_to_modify = {
    (var.prefix) = {
      policy_assignments = {
        Update-Ring1 = {
          parameters = {
            maintenanceConfigurationResourceId = jsonencode({ value = local.maintenance_configuration_resource_id })
            tagValues                          = jsonencode({ value = [{ key = "Update Manager Policy", value = "Ring1" }] })
            effect                             = jsonencode({ value = "DeployIfNotExists" })
          }
          identity     = "UserAssigned"
          identity_ids = [local.user_assigned_identity_resource_id]
        }
      }
    }
  }
}
