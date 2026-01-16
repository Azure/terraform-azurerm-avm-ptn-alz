# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      path = "platform/alz",
      ref  = "2025.09.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

locals {
  intermediate_root_management_group_id = [for management_group in jsondecode(file("${path.module}/lib/alz.alz_architecture_definition.json")).management_groups : management_group.id if management_group.parent_id == null][0]
  parent_management_group_id            = "alz-test-mg-${var.random_suffix}"
}

resource "azapi_resource" "example" {
  name      = local.parent_management_group_id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${data.azapi_client_config.current.tenant_id}"
        }
      }
      displayName = "ALZ Test MG ${var.random_suffix}"
    }
  }
  response_export_values = []
  retry = {
    error_message_regex = [
      "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      "Permission to Microsoft.Management/managementGroups on resources of type 'Write' is required on the management group or its ancestors."
    ]
  }

  timeouts {
    create = "60m"
    delete = "5m"
    read   = "60m"
    update = "5m"
  }
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz"
  location           = "northeurope"
  parent_resource_id = azapi_resource.example.name
  enable_telemetry   = var.enable_telemetry
  subscription_placement = {
    test = {
      subscription_id       = data.azapi_client_config.current.subscription_id
      management_group_name = local.intermediate_root_management_group_id
    }
  }
  subscription_placement_destroy_move_to_parent_resource_id_enabled = true
}
