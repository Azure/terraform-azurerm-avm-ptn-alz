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
  intermediate_root_management_group_id = "${var.prefix}-alz"
  parent_management_group_id            = "${var.prefix}-alz-parent"
}

resource "azapi_resource" "parent" {
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
      displayName = "ALZ Test MG ${var.prefix}"
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

resource "azapi_resource" "intermediate_root" {
  name      = local.intermediate_root_management_group_id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = azapi_resource.parent.id
        }
      }
      displayName = "${var.prefix} ALZ root"
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

resource "azapi_resource_action" "subscription_placement_create" {
  method                 = "PUT"
  resource_id            = "/providers/Microsoft.Management/managementGroups/${azapi_resource.intermediate_root.name}/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
  response_export_values = []
  when                   = "apply"
}

resource "azapi_resource_action" "subscription_placement_delete" {
  method                 = "PUT"
  resource_id            = "/providers/Microsoft.Management/managementGroups/${data.azapi_client_config.current.tenant_id}/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
  response_export_values = []
  when                   = "destroy"

  depends_on = [azapi_resource.intermediate_root]
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz"
  location           = "northeurope"
  parent_resource_id = azapi_resource.parent.name
  dependencies = {
    management_groups = [
      azapi_resource_action.subscription_placement_create,
      azapi_resource_action.subscription_placement_delete,
    ]
  }
  enable_telemetry = var.enable_telemetry
  subscription_placement = {
    test = {
      subscription_id       = data.azapi_client_config.current.subscription_id
      management_group_name = "${var.prefix}-management"
    }
  }
  subscription_placement_destroy_behavior = "intermediate_root"
}
