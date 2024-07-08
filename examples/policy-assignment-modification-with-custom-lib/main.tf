# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      ref  = "2024.07.01"
    },
    {
      custom_url = "${path.cwd}/lib"
    }
  ]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "update_manager" {
  location = "uksouth"
  name     = "rg_test"
}

resource "azurerm_maintenance_configuration" "this" {
  location            = azurerm_resource_group.update_manager.location
  name                = "ring1"
  resource_group_name = azurerm_resource_group.update_manager.name
  scope               = "InGuestPatch"

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

module "alz" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = "northeurope"
  policy_assignments_to_modify = {
    alzroot = {
      policy_assignments = {
        Update-Ring1 = {
          parameters = jsonencode({
            maintenanceConfigurationResourceId = azurerm_maintenance_configuration.this.id
          })
        }
      }
    }
  }
}
