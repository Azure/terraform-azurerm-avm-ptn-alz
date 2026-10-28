mock_provider "alz" {}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  architecture_name  = "test"
  location           = "test"
  parent_resource_id = "test"
}

run "default_input" {
  command = apply

  assert {
    condition     = var.telemetry_additional_content == null
    error_message = "Additional telemetry content must remain optional and default to null."
  }

  assert {
    condition = (
      length(azapi_resource.telemetry) == 1 &&
      azapi_resource.telemetry[0].name == format("%s.0-0-0.x.%s", local.avm_metadata.telemetryIdPrefix, substr(sha1(terraform_data.telemetry[0].id), 0, 4))
    )
    error_message = "Telemetry must default to enabled and a null map must leave the base deployment name unchanged."
  }

  assert {
    condition     = azapi_resource.telemetry[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000"
    error_message = "Telemetry must use the active subscription scope."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "empty_input" {
  command = apply

  variables {
    telemetry_additional_content = {}
  }

  assert {
    condition     = length(var.telemetry_additional_content) == 0
    error_message = "An empty map must remain accepted."
  }

  assert {
    condition     = azapi_resource.telemetry[0].name == format("%s.0-0-0.x.%s", local.avm_metadata.telemetryIdPrefix, substr(sha1(terraform_data.telemetry[0].id), 0, 4))
    error_message = "An empty map must not add a separator or suffix."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "custom_input_sorted_suffix" {
  command = apply

  variables {
    telemetry_additional_content = {
      z = "2"
      a = "1"
    }
  }

  assert {
    condition     = endswith(azapi_resource.telemetry[0].name, "-a-1-z-2")
    error_message = "Generated telemetry must append sorted, hyphen-separated key-value pairs."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "custom_input_with_telemetry_disabled" {
  command = apply

  variables {
    enable_telemetry = false
    telemetry_additional_content = {
      "invalid key" = "invalid value"
    }
  }

  assert {
    condition     = !var.enable_telemetry && length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Opting out must prevent all telemetry resources, including validation of unused custom content."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "null_map_value" {
  command = apply

  variables {
    telemetry_additional_content = {
      k = null
    }
  }

  assert {
    condition     = endswith(azapi_resource.telemetry[0].name, "-k-")
    error_message = "A nullable string map value must retain its key and encode the value as an empty string."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "invalid_key" {
  command = plan

  variables {
    telemetry_additional_content = {
      "invalid key" = "value"
    }
  }

  expect_failures = [azapi_resource.telemetry]
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "invalid_value" {
  command = plan

  variables {
    telemetry_additional_content = {
      key = "invalid/value"
    }
  }

  expect_failures = [azapi_resource.telemetry]
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "maximum_name_length" {
  command = apply

  variables {
    telemetry_additional_content = {
      k = join("", [for i in range(28) : "x"])
    }
  }

  assert {
    condition     = length(azapi_resource.telemetry[0].name) == 64 && endswith(azapi_resource.telemetry[0].name, "-k-${join("", [for i in range(28) : "x"])}")
    error_message = "An exactly 64-character deployment name must be accepted without truncating custom content."
  }
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}

run "overlong_name" {
  command = plan

  variables {
    telemetry_additional_content = {
      k = join("", [for i in range(29) : "x"])
    }
  }

  expect_failures = [azapi_resource.telemetry]
  providers = {
    alz    = alz
    azapi  = azapi
    random = random
    time   = time
  }
}
