# Regression test for issue #4350.
#
# Verifies that the VMSS built-in managed identity policy uses
# userAssignedIdentityResourceId for the assignPermissions override.
#
# The policy definition ID is:
# 516187d4-ef64-4a1b-ad6b-a7348502976c
#
# privateDnsZoneId is not a parameter of this VMSS built-in policy.

mock_provider "alz" {}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  architecture_name  = "test"
  location           = "swedencentral"
  parent_resource_id = "test"
}

run "vmss_assign_permissions_uses_user_assigned_identity_resource_id" {
  command = plan

  assert {
    condition = contains(
      var.override_policy_definition_parameter_assign_permissions_set,
      {
        definition_name = "516187d4-ef64-4a1b-ad6b-a7348502976c"
        parameter_name  = "userAssignedIdentityResourceId"
      }
    )

    error_message = "VMSS managed identity policy must set assignPermissions on userAssignedIdentityResourceId."
  }

  assert {
    condition = !contains(
      var.override_policy_definition_parameter_assign_permissions_set,
      {
        definition_name = "516187d4-ef64-4a1b-ad6b-a7348502976c"
        parameter_name  = "privateDnsZoneId"
      }
    )

    error_message = "VMSS managed identity policy must not set assignPermissions on the nonexistent privateDnsZoneId parameter."
  }
}