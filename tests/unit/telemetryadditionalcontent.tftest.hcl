mock_provider "alz" {}
mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  architecture_name  = "test"
  location           = "test"
  parent_resource_id = "test"
}

run "default_input" {
  command = plan

  assert {
    condition     = var.telemetry_additional_content == null
    error_message = "The deprecated input must remain optional and default to null."
  }
}

run "empty_input" {
  command = plan

  variables {
    telemetry_additional_content = {}
  }

  assert {
    condition     = length(var.telemetry_additional_content) == 0
    error_message = "An empty deprecated input must remain accepted without a warning."
  }
}

run "custom_input_warns" {
  command = plan

  variables {
    telemetry_additional_content = {
      custom_tag = "legacy"
    }
  }

  expect_failures = [check.telemetry_additional_content_deprecated]

  assert {
    condition     = var.telemetry_additional_content["custom_tag"] == "legacy"
    error_message = "Existing custom inputs must remain accepted while reporting their deprecation."
  }
}

run "custom_input_warns_with_telemetry_disabled" {
  command = plan

  variables {
    enable_telemetry = false
    telemetry_additional_content = {
      custom_tag = "legacy"
    }
  }

  expect_failures = [check.telemetry_additional_content_deprecated]

  assert {
    condition     = !var.enable_telemetry
    error_message = "The deprecated input must not change the telemetry opt-out."
  }
}
