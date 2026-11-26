mock_provider "alz" {}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  parent_resource_id = "test"
  location           = "test"
  architecture_name  = "test"
}

run "no_registrations_by_default" {
  command = plan

  assert {
    condition     = length(azapi_resource_action.management_group_resource_provider_registrations) == 0
    error_message = "No management group resource provider registrations should be created when the input is omitted."
  }
}

run "single_registration" {
  command = plan

  variables {
    management_group_resource_provider_registrations = {
      alz = [
        "Microsoft.Network",
      ]
    }
  }

  assert {
    condition     = length(azapi_resource_action.management_group_resource_provider_registrations) == 1
    error_message = "Exactly one resource provider registration should be created."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].resource_id == "/providers/Microsoft.Management/managementGroups/alz"
    error_message = "The registration resource_id should target only the management group."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].action == "providers/Microsoft.Network/register"
    error_message = "The registration action should contain the provider namespace and register operation."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].method == "POST"
    error_message = "The resource provider registration should use POST."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].type == var.resource_types.management_group
    error_message = "The registration action should use the management group resource type."
  }
}

run "multiple_registrations" {
  command = plan

  variables {
    management_group_resource_provider_registrations = {
      alz = [
        "Microsoft.Insights",
        "Microsoft.Network",
      ]
    }
  }

  assert {
    condition     = length(azapi_resource_action.management_group_resource_provider_registrations) == 2
    error_message = "Two resource provider registrations should be created."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Insights"].action == "providers/Microsoft.Insights/register"
    error_message = "Microsoft.Insights should use the expected registration action."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].action == "providers/Microsoft.Network/register"
    error_message = "Microsoft.Network should use the expected registration action."
  }
}

run "multiple_management_groups" {
  command = plan

  variables {
    management_group_resource_provider_registrations = {
      alz = [
        "Microsoft.Network",
      ]
      platform = [
        "Microsoft.Insights",
      ]
    }
  }

  assert {
    condition     = length(azapi_resource_action.management_group_resource_provider_registrations) == 2
    error_message = "One registration should be created for each management group and provider combination."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["alz/Microsoft.Network"].resource_id == "/providers/Microsoft.Management/managementGroups/alz"
    error_message = "Microsoft.Network should target the alz management group."
  }

  assert {
    condition     = azapi_resource_action.management_group_resource_provider_registrations["platform/Microsoft.Insights"].resource_id == "/providers/Microsoft.Management/managementGroups/platform"
    error_message = "Microsoft.Insights should target the platform management group."
  }
}
