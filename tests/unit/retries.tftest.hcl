provider "alz" {
  library_references = [{
    custom_url = "./tests/unit/testdata/policyroleassignmentsenabled"
  }]
}

mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  architecture_name  = "custom"
  enable_telemetry   = false
  location           = "swedencentral"
  parent_resource_id = "pratestroot"
}

run "policy_definition_defaults" {
  command = plan

  assert {
    condition     = azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.error_message_regex == tolist(["AuthorizationFailed", "PolicyDefinitionNotFound"])
    error_message = "Policy definitions must retry authorization propagation and delayed policy visibility."
  }

  assert {
    condition = alltrue([
      for resource_type, settings in var.retries : !contains(settings.error_message_regex, "PolicyDefinitionNotFound")
      if resource_type != "policy_definitions"
    ])
    error_message = "Policy-definition not-found retries must not affect other resource types."
  }
}

run "policy_definition_override" {
  command = plan

  variables {
    retries = {
      policy_definitions = {
        error_message_regex  = ["CustomPolicyError"]
        interval_seconds     = 3
        max_interval_seconds = 15
        multiplier           = 2
        randomization_factor = 0.5
      }
    }
  }

  assert {
    condition     = azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.error_message_regex == tolist(["CustomPolicyError"])
    error_message = "Consumer retry expressions must replace the policy-definition defaults."
  }

  assert {
    condition = (
      azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.interval_seconds == 3 &&
      azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.max_interval_seconds == 15 &&
      azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.multiplier == 2 &&
      azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.randomization_factor == 0.5
    )
    error_message = "Consumer policy-definition retry settings must reach the resource unchanged."
  }
}

run "policy_definition_null_uses_defaults" {
  command = plan

  variables {
    retries = {
      policy_definitions = {
        error_message_regex = null
      }
    }
  }

  assert {
    condition     = azapi_resource.policy_definitions["pratest/Deploy-PRA-Test-Def"].retry.error_message_regex == tolist(["AuthorizationFailed", "PolicyDefinitionNotFound"])
    error_message = "An explicit null must retain the optional attribute's policy-definition defaults."
  }
}
