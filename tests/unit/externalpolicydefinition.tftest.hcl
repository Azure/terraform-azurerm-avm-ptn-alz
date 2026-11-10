# Regression test for issue #4098.
#
# Verifies that policy_assignments_to_modify.policy_definition_id can override
# the policy definition ID resolved from the ALZ library. This supports policy
# definitions created externally, while ALZ continues to manage the assignment.

provider "alz" {
  library_references = [{
    custom_url = "./tests/unit/testdata/externalpolicydefinition"
  }]
}

mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  location           = "swedencentral"
  architecture_name  = "custom"
  parent_resource_id = "externalpolicytest"
}

run "baseline_uses_library_policy_definition" {
  command = plan

  assert {
    condition     = azapi_resource.policy_assignments["externalpolicytest/4098-External-Policy"].body.properties.policyDefinitionId == "/providers/Microsoft.Management/managementGroups/externalpolicytest/providers/Microsoft.Authorization/policyDefinitions/4098-Placeholder-Definition"
    error_message = "Baseline assignment should use the policy definition resolved from the ALZ library."
  }
}

run "external_policy_definition_id_overrides_library_value" {
  command = plan

  variables {
    policy_assignments_to_modify = {
      externalpolicytest = {
        policy_assignments = {
          "4098-External-Policy" = {
            policy_definition_id = "/providers/Microsoft.Management/managementGroups/externalpolicytest/providers/Microsoft.Authorization/policyDefinitions/4098-External-Policy"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.policy_assignments["externalpolicytest/4098-External-Policy"].body.properties.policyDefinitionId == "/providers/Microsoft.Management/managementGroups/externalpolicytest/providers/Microsoft.Authorization/policyDefinitions/4098-External-Policy"
    error_message = "policy_definition_id must override the ALZ library policy definition ID with the externally managed definition ID."
  }
}
