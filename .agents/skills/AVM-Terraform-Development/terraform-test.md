# Writing Terraform Tests for AVM Modules

This sub-skill covers writing `.tftest.hcl` files for Azure Verified Modules (AVM). It adapts Terraform's built-in testing framework to AVM conventions.

## AVM Test Directory Structure

Tests MUST live in one of two directories. No other location is permitted.

```
<module-root>/
  tests/
    unit/
      unit.tftest.hcl          # Unit tests WITH mock_provider blocks
      setup.sh                  # Optional pre-test setup script
    integration/
      integration.tftest.hcl   # Integration tests WITHOUT mock_provider blocks
      setup.sh                  # Optional pre-test setup script
```

Submodules under `./modules/` follow the same pattern — each can have its own `tests/unit/` and `tests/integration/` directories.

## Unit Tests vs Integration Tests

| Aspect | Unit Tests (`tests/unit`) | Integration Tests (`tests/integration`) |
|---|---|---|
| **Mock providers** | YES — mock ALL providers | NO — uses real providers |
| **Real infrastructure** | None created | Creates and destroys real Azure resources |
| **Command** | `command = apply` (safe with mocks) | `command = apply` (default) |
| **Speed** | Fast (seconds) | Slow (minutes) |
| **Credentials needed** | No | Yes (Azure) |
| **Run command** | `PORCH_NO_TUI=1 ./avm tf-test-unit` | `PORCH_NO_TUI=1 ./avm tf-test-integration` |

**Critical rule**: Unit tests use `command = apply` (NOT `command = plan`) because mocked providers make apply safe and allow testing resource creation logic.

## Unit Test Template

Every AVM module uses the AzAPI provider. Unit tests MUST mock **all** providers declared in `terraform.tf` `required_providers`. AVM modules always include `azapi`, `modtm`, and `random`.

```hcl
# tests/unit/unit.tftest.hcl

mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location = "eastus"
}

run "apply" {
  command = apply

  assert {
    condition     = can(modtm_telemetry.telemetry)
    error_message = "Telemetry resource should be created when enable_telemetry is true (default)."
  }
}
```

### Mock Provider with Defaults

When you need mocked resources to return specific values for assertions:

```hcl
mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      name = "vnet-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
```

### AzureRM Module Variant

For legacy AzureRM-based modules, mock `azurerm` instead of (or in addition to) `azapi`:

```hcl
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
```

## Integration Test Template

Integration tests do NOT include `mock_provider` blocks. They create real Azure infrastructure.

```hcl
# tests/integration/integration.tftest.hcl

variables {
  location = "eastus"
}

run "apply" {
  command = apply

  assert {
    condition     = can(modtm_telemetry.telemetry)
    error_message = "Telemetry resource should be created when enable_telemetry is true (default)."
  }
}
```

## Core Concepts

### Run Blocks

Each `run` block executes a test scenario. Run blocks execute sequentially by default.

```hcl
run "test_resource_creation" {
  command = apply

  assert {
    condition     = azapi_resource.example.id != ""
    error_message = "Resource should be created with a valid ID"
  }

  assert {
    condition     = output.resource_id != ""
    error_message = "Resource ID output should not be empty"
  }
}
```

**Run block attributes:**

- `command` — `apply` (default) or `plan`
- `variables` — Override test-level variable values
- `module` — Reference alternate modules (local or registry sources only)
- `assert` — Validation conditions (multiple allowed)
- `expect_failures` — Specify expected validation failures
- `plan_options` — Configure plan behavior (`mode`, `refresh`, `replace`, `target`)
- `state_key` — Manage state file isolation
- `parallel` — Enable parallel execution (`true`/`false`)

### Variables

Define at file level (applied to all run blocks) or within individual run blocks. Run-level variables override file-level ones.

```hcl
# File-level — applied to all run blocks
variables {
  location = "eastus"
  tags = {
    Environment = "test"
  }
}

run "test_with_override" {
  command = apply

  # Override file-level variable
  variables {
    location = "westus2"
  }

  assert {
    condition     = azapi_resource.example.location == "westus2"
    error_message = "Location should be overridden to westus2"
  }
}
```

**Referencing prior run block outputs:**

```hcl
run "setup_resource_group" {
  command = apply
}

run "test_with_dependency" {
  command = apply

  variables {
    resource_group_id = run.setup_resource_group.resource_group_id
  }

  assert {
    condition     = azapi_resource.example.parent_id == run.setup_resource_group.resource_group_id
    error_message = "Resource should be in the created resource group"
  }
}
```

### Assert Blocks

Assert blocks validate conditions. All assertions must pass for the test to succeed.

```hcl
assert {
  condition     = <expression>
  error_message = "Descriptive failure message"
}
```

**Common assertion patterns:**

```hcl
# Resource existence
assert {
  condition     = can(azapi_resource.example)
  error_message = "Resource should exist"
}

# Output validation
assert {
  condition     = output.resource_id != ""
  error_message = "Resource ID output should not be empty"
}

# Count / length
assert {
  condition     = length(output.subnet_ids) == 3
  error_message = "Should create exactly 3 subnets"
}

# Complex conditions
assert {
  condition = alltrue([
    for subnet in azapi_resource.subnets :
    can(regex("^/subscriptions/", subnet.id))
  ])
  error_message = "All subnets should have valid Azure resource IDs"
}
```

### Expect Failures

Test that validation rules correctly reject invalid input. The test **passes** if the specified object reports a failure.

```hcl
run "test_invalid_location_rejected" {
  command = apply

  variables {
    location = ""
  }

  expect_failures = [
    var.location
  ]
}
```

### Testing Conditional Resources

```hcl
run "test_feature_enabled" {
  command = apply

  variables {
    location          = "eastus"
    enable_monitoring = true
  }

  assert {
    condition     = length(azapi_resource.diagnostic_settings) == 1
    error_message = "Diagnostic settings should be created when monitoring is enabled"
  }
}

run "test_feature_disabled" {
  command = apply

  variables {
    location          = "eastus"
    enable_monitoring = false
  }

  assert {
    condition     = length(azapi_resource.diagnostic_settings) == 0
    error_message = "Diagnostic settings should not be created when monitoring is disabled"
  }
}
```

### Module Block

Test a specific submodule rather than the root configuration. Only **local** and **registry** module sources are supported.

```hcl
run "test_submodule" {
  command = apply

  module {
    source = "./modules/subnet"
  }

  variables {
    name              = "test-subnet"
    address_prefixes  = ["10.0.1.0/24"]
    virtual_network_id = run.setup_vnet.virtual_network_id
  }

  assert {
    condition     = output.subnet_id != ""
    error_message = "Subnet should be created"
  }
}
```

### Parallel Execution

Run blocks with `parallel = true` execute concurrently. They must not reference each other's outputs and must use different state files.

```hcl
run "test_module_a" {
  command  = apply
  parallel = true

  module {
    source = "./modules/module-a"
  }

  variables {
    location = "eastus"
  }

  assert {
    condition     = output.id != ""
    error_message = "Module A should produce output"
  }
}

run "test_module_b" {
  command  = apply
  parallel = true

  module {
    source = "./modules/module-b"
  }

  variables {
    location = "eastus"
  }

  assert {
    condition     = output.id != ""
    error_message = "Module B should produce output"
  }
}
```

### Optional Setup Script

If `tests/unit/setup.sh` or `tests/integration/setup.sh` exists, it runs automatically before `terraform init`. Use this for environment preparation.

## Running Tests

Tests run inside the AVM container via the `./avm` wrapper. Always prefix with `PORCH_NO_TUI=1`.

```bash
# Unit tests
PORCH_NO_TUI=1 ./avm tf-test-unit

# Integration tests
PORCH_NO_TUI=1 ./avm tf-test-integration
```

The test runner automatically:
1. Checks that `tests/unit/` or `tests/integration/` exists (skips gracefully if not)
2. Copies the working directory to a temp location
3. Cleans `.terraform`, lock files, and state files
4. Runs `setup.sh` if present
5. Runs `terraform init -test-directory ./tests/<type>`
6. Runs `terraform test -test-directory ./tests/<type>`
7. Repeats for each submodule under `./modules/` (in parallel)
8. Cleans up

## Cleanup and Destruction

Resources created by integration tests are destroyed automatically in **reverse run block order** after test completion. This handles dependency ordering correctly.

For debugging, the `terraform test -no-cleanup` flag prevents automatic destruction — but note that this must be run directly, not via `./avm`.

## Best Practices

1. **Always mock all providers** in unit tests — check `terraform.tf` `required_providers` for the full list. AVM modules always have at least `azapi`, `modtm`, and `random`.
2. **Use `command = apply`** for unit tests (not `plan`) — mocked providers make apply safe and allow testing resource creation.
3. **Write clear error messages** — assertion messages should describe the expected behavior, not restate the condition.
4. **Set `location`** in the `variables` block — it is a required variable in all AVM modules with no default.
5. **Test validation rules** — use `expect_failures` to verify that invalid inputs are rejected.
6. **Test conditional logic** — verify that optional features create resources when enabled and skip them when disabled.
7. **Keep tests focused** — each run block should test one scenario or behavior.
8. **Test outputs** — verify that module outputs are populated and have correct formats.

## Troubleshooting

If tests fail, refer to the official AVM testing documentation:

<https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/contributing/terraform/testing.md>

**Common issues:**

- **Missing mock provider**: Unit test fails because a required provider is not mocked. Check `terraform.tf` for all `required_providers`.
- **Credential errors in integration tests**: Ensure Azure credentials are available (e.g., `az login` or service principal env vars).
- **State conflicts**: Use `state_key` when multiple run blocks reference different modules.
- **Test not found**: Ensure test files are in the correct directory (`tests/unit/` or `tests/integration/`) and have the `.tftest.hcl` extension.

## References

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Test Command Reference](https://developer.hashicorp.com/terraform/cli/commands/test)
- [Mock Providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
