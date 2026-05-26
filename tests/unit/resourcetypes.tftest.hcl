mock_provider "alz" {}
mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  management_group_hierarchy_settings = {
    default_management_group_name            = "test"
    require_authorization_for_group_creation = true
    update_existing                          = false
  }
  parent_resource_id = "test"
  location           = "test"
  architecture_name  = "test"
}

run "defaults" {
  command = plan

  assert {
    condition     = var.resource_types.management_group == "Microsoft.Management/managementGroups@2023-04-01"
    error_message = "Default management_group type should be Microsoft.Management/managementGroups@2023-04-01."
  }

  assert {
    condition     = var.resource_types.management_group_settings == "Microsoft.Management/managementGroups/settings@2023-04-01"
    error_message = "Default management_group_settings type should be Microsoft.Management/managementGroups/settings@2023-04-01."
  }

  assert {
    condition     = var.resource_types.management_group_subscription == "Microsoft.Management/managementGroups/subscriptions@2023-04-01"
    error_message = "Default management_group_subscription type should be Microsoft.Management/managementGroups/subscriptions@2023-04-01."
  }

  assert {
    condition     = var.resource_types.policy_assignment == "Microsoft.Authorization/policyAssignments@2024-04-01"
    error_message = "Default policy_assignment type should be Microsoft.Authorization/policyAssignments@2024-04-01."
  }

  assert {
    condition     = var.resource_types.policy_definition == "Microsoft.Authorization/policyDefinitions@2023-04-01"
    error_message = "Default policy_definition type should be Microsoft.Authorization/policyDefinitions@2023-04-01."
  }

  assert {
    condition     = var.resource_types.policy_set_definition == "Microsoft.Authorization/policySetDefinitions@2023-04-01"
    error_message = "Default policy_set_definition type should be Microsoft.Authorization/policySetDefinitions@2023-04-01."
  }

  assert {
    condition     = var.resource_types.role_assignment == "Microsoft.Authorization/roleAssignments@2022-04-01"
    error_message = "Default role_assignment type should be Microsoft.Authorization/roleAssignments@2022-04-01."
  }

  assert {
    condition     = var.resource_types.role_definition == "Microsoft.Authorization/roleDefinitions@2022-04-01"
    error_message = "Default role_definition type should be Microsoft.Authorization/roleDefinitions@2022-04-01."
  }

  assert {
    condition     = var.resource_types.user_assigned_identity == "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
    error_message = "Default user_assigned_identity type should be Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31."
  }

  assert {
    condition     = azapi_resource.hierarchy_settings[0].type == "Microsoft.Management/managementGroups/settings@2023-04-01"
    error_message = "The default management_group_settings type should be applied to the hierarchy_settings resource."
  }
}

run "override_propagates_to_resource" {
  command = plan

  variables {
    resource_types = {
      management_group_settings = "Microsoft.Management/managementGroups/settings@2020-05-01"
    }
  }

  assert {
    condition     = azapi_resource.hierarchy_settings[0].type == "Microsoft.Management/managementGroups/settings@2020-05-01"
    error_message = "Overriding var.resource_types.management_group_settings should change the type argument on azapi_resource.hierarchy_settings."
  }

  assert {
    condition     = var.resource_types.management_group == "Microsoft.Management/managementGroups@2023-04-01"
    error_message = "Unspecified keys in var.resource_types must keep their default values."
  }
}

run "casing_override_for_issue_4165" {
  command = plan

  variables {
    resource_types = {
      role_definition = "Microsoft.Authorization/RoleDefinitions@2022-04-01"
    }
  }

  assert {
    condition     = var.resource_types.role_definition == "Microsoft.Authorization/RoleDefinitions@2022-04-01"
    error_message = "var.resource_types must accept casing overrides for AzAPI types (mitigation for Azure/Azure-Landing-Zones#4165)."
  }
}

run "invalid_type_string_rejected" {
  command = plan

  variables {
    resource_types = {
      role_definition = "Microsoft.Authorization/roleDefinitions"
    }
  }

  expect_failures = [var.resource_types]
}
