# Regression test for issue #4226.
#
# Verifies that setting `role_assignments_enabled = false` on a policy
# assignment removes ONLY its generated policy role assignment(s), while the
# policy assignment itself and its managed identity are still created.
#
# Uses the real `alz` provider (so `data.alz_architecture.this.policy_role_assignments`
# is computed from the library) with `azapi`/`modtm` mocked and `command = plan`,
# so no Azure authentication is required. The instance count of
# `azapi_resource.policy_role_assignments` reflects the real `for_each` over
# `local.policy_role_assignments`, which is what the fix filters.
#
# The custom `Deploy-PRA-Test` assignment targets a self-contained
# DeployIfNotExists policy definition that declares `roleDefinitionIds`, so the
# alz provider generates a policy role assignment from library data alone (no
# Azure lookups required).

provider "alz" {
  library_references = [{
    custom_url = "./tests/unit/testdata/policyroleassignmentsenabled"
  }]
}

mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  location           = "swedencentral"
  architecture_name  = "custom"
  parent_resource_id = "pratestroot"
}

run "baseline_role_assignment_created" {
  command = plan

  assert {
    condition     = length(output.policy_role_assignment_resource_ids) > 0
    error_message = "Baseline: at least one policy role assignment should be planned for the DeployIfNotExists assignment."
  }

  assert {
    condition     = length(output.policy_assignment_resource_ids) == 1
    error_message = "Baseline: the policy assignment should be planned."
  }
}

run "role_assignments_disabled_removes_only_role_assignment" {
  command = plan

  variables {
    policy_assignments_to_modify = {
      pratest = {
        policy_assignments = {
          "Deploy-PRA-Test" = {
            role_assignments_enabled = false
          }
        }
      }
    }
  }

  assert {
    condition     = length(output.policy_role_assignment_resource_ids) == 0
    error_message = "With role_assignments_enabled = false the policy role assignment must NOT be created."
  }

  assert {
    condition     = length(output.policy_assignment_resource_ids) == 1
    error_message = "The policy assignment itself must still be created when role_assignments_enabled = false."
  }
}
