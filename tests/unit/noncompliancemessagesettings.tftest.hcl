mock_provider "alz" {}
mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  parent_resource_id = "test"
  location           = "test"
  architecture_name  = "test"
}

run "default" {
  command = plan

  # The variable defaults to {}, which means default_message is null and merge_mode is "replace".
  # This is the backwards-compatible default behaviour of the alz provider — the provider does
  # not inject a default non-compliance message when default_message is null.
  assert {
    condition     = var.policy_assignment_non_compliance_message_settings.default_message == null
    error_message = "The default_message should default to null for backwards compatibility with the alz provider."
  }

  assert {
    condition     = var.policy_assignment_non_compliance_message_settings.merge_mode == "replace"
    error_message = "The merge_mode should default to 'replace'."
  }

  assert {
    condition     = data.alz_architecture.this.default_non_compliance_message_settings.default_message == null
    error_message = "The default_message passed to the alz provider should be null when not set."
  }

  assert {
    condition     = data.alz_architecture.this.default_non_compliance_message_settings.merge_mode == "replace"
    error_message = "The merge_mode passed to the alz provider should be 'replace' when not set."
  }
}

run "set_default_message" {
  command = plan

  variables {
    policy_assignment_non_compliance_message_settings = {
      default_message = "This resource {enforcementMode} be compliant with the assigned policy."
    }
  }

  assert {
    condition     = data.alz_architecture.this.default_non_compliance_message_settings.default_message == "This resource {enforcementMode} be compliant with the assigned policy."
    error_message = "The default_message should be passed through to the alz provider."
  }

  assert {
    condition     = data.alz_architecture.this.default_non_compliance_message_settings.merge_mode == "replace"
    error_message = "The merge_mode should default to 'replace' when only default_message is set."
  }
}

run "set_merge_mode_prefer_existing" {
  command = plan

  variables {
    policy_assignment_non_compliance_message_settings = {
      default_message = "Default message."
      merge_mode      = "prefer_existing"
    }
  }

  assert {
    condition     = data.alz_architecture.this.default_non_compliance_message_settings.merge_mode == "prefer_existing"
    error_message = "The merge_mode should be passed through to the alz provider."
  }
}

run "invalid_merge_mode" {
  command = plan

  variables {
    policy_assignment_non_compliance_message_settings = {
      default_message = "Default message."
      merge_mode      = "invalid"
    }
  }

  expect_failures = [var.policy_assignment_non_compliance_message_settings]
}
