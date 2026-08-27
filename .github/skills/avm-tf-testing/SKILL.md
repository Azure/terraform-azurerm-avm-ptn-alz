---
name: avm-tf-testing
description: Use for AVM Terraform validation, provider-mocked unit tests, real-Azure integration tests, E2E example tests, PowerShell hooks, OIDC, policy checks, and Avm.Authoring CI behavior.
---

# AVM Terraform Testing

Use PowerShell 7.4 or later with the `Avm.Authoring` module. The old repository launcher, Make targets, Porch flags, and container workflow are retired.

```pwsh
Install-PSResource -Name Avm.Authoring -Repository PSGallery -TrustRepository
Import-Module Avm.Authoring
avm version
```

## Test surfaces

| Surface | Command | Purpose |
| --- | --- | --- |
| Terraform validation | `avm test` | Run Terraform initialization when needed and validate the module. |
| Unit tests | `avm test unit` | Run `tests/unit/*.tftest.hcl` with mocked providers. |
| Integration tests | `avm test integration` | Run `tests/integration/*.tftest.hcl` against real Azure. |
| E2E examples | `avm test e2e` | Apply, idempotency-check, and destroy runnable `examples/*`. |
| Policy | `avm check policy` | Build example plan JSON and evaluate APRL and AVMSEC through Conftest. |
| Full PR gate | `avm pr-check` | Run the clean-worktree PR gauntlet; it does not replace standalone test tiers. |

Always name the tier when tests are expected. Bare `avm test` validates Terraform; it does not run unit, integration, and E2E suites.

## Unit tests

Place tests in `tests/unit`. Mock every provider declared by the module:

Every new resource-deploying module therefore mocks `azapi`. Declare or mock `azurerm` only when a test configures or exercises independently justified `azurerm_*` exception blocks.

```hcl
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

run "creates_the_resource" {
  command = apply

  variables {
    name      = "example"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
  }

  assert {
    condition     = output.resource_id != null
    error_message = "The module should return the primary resource ID."
  }
}
```

Use mocked `apply` so computed values and resource creation paths can be asserted without Azure. Add focused tests for:

- defaults and optional features;
- validation failures with `expect_failures`;
- conditional resources;
- outputs;
- parent-to-submodule propagation; and
- `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` wiring.

For detailed `.tftest.hcl` syntax, mocking, assertions, and troubleshooting patterns, see the [Terraform test reference](references/terraform-test.md).

## Integration tests

Place real-Azure Terraform tests in `tests/integration`. Do not mock providers. Keep each run focused, use unique names, and verify behaviors that cannot be proven from a mocked plan.

Test configurations, fixtures, and setup or teardown Terraform use AzAPI for every control-plane and ordinary supporting resource. If test scaffolding needs a direct Azure dependency that the module under test does not create, use an AzAPI resource, data source, or action and include `Azure/azapi` in that Terraform root's `required_providers`.

AzureRM may be configured or exercised only when required by permitted `azurerm_*` resource or data-source blocks. Each block must independently implement one specific unsupported data-plane/non-ARM operation, document the exact block and why no applicable AzAPI resource or action can implement it, link the upstream AzAPI issue or pull request, and be replaced when support ships. One valid block does not authorize another.

Authenticate without committed secrets. Local runs can use an authenticated Azure CLI session or supported `ARM_*` environment variables. CI uses OIDC with least-privilege identities and protected environments.

## E2E examples

Each direct child of `examples/` is a standalone Terraform root. Discover and target examples with:

```pwsh
avm test e2e --list
avm test e2e --example default
```

Without `--example`, runnable examples execute sequentially. A `.e2eignore` marker excludes an example from discovery. E2E performs:

1. Terraform initialization;
2. deployment;
3. a no-change idempotency plan;
4. cleanup; and
5. bounded retries for recognized capacity failures.

An idempotency diff is a failure and is never hidden by a retry.

Every runnable example and E2E configuration uses AzAPI for direct Azure setup and control-plane resources, and its `required_providers` includes `Azure/azapi`. It may include AzureRM only to configure or exercise independently justified unsupported data-plane/non-ARM blocks. A legacy `/azurerm` suffix in a published AVM module source is a Registry namespace and is not an AzureRM provider declaration.

For exceptional manual workflows such as distributing examples across subscriptions or retaining deployments for inspection, see the [manual example-testing reference](references/example-test.md).

## PowerShell hooks

Supported hooks run in isolated `pwsh` processes:

- `tests/unit/setup.ps1`;
- `tests/integration/setup.ps1`;
- `examples/<name>/pre.ps1`;
- `examples/<name>/post.ps1`; and
- `examples/<name>/tflint-pre.ps1`.

Shell equivalents such as `setup.sh`, `pre.sh`, `post.sh`, or `tflint-pre.sh` are rejected as configuration errors. Port all hooks to PowerShell.

Use hooks only for required environment preparation or cleanup. Keep Terraform assertions in Terraform tests.

## Authoring gates

Before committing:

```pwsh
avm pre-commit
```

For Terraform this applies sync, fixable convention rules, transforms, formatting, and docs. It is not a substitute for unit or real-Azure tests.

After reviewing and committing all changes:

```pwsh
avm pr-check
```

The worktree must be clean. PR check runs sync, format, transform, lint, policy, convention, validation, and docs. Unit tests are deliberately a separate reusable-workflow job rather than repeated inside PR check.

## CI expectations

- Use the governance-managed reusable Terraform workflow.
- Use OIDC and a user-assigned identity or equivalent secretless federation.
- Keep test environments least privilege and isolate subscriptions where practical.
- Treat `skipped` as different from `pass`. If the change requires a test tier, an undiscovered or skipped tier is not evidence.
- Preserve logs for failed Terraform run blocks, plans, policy findings, and cleanup failures.

## Debugging

Run the smallest command that reproduces the issue:

```pwsh
avm test unit
avm test integration
avm test e2e --example default
avm lint
avm check policy
```

Use `-Path <module-directory>` when testing a module outside the current directory and `-Ecosystem terraform` when context detection is ambiguous. Use `--passthru` for structured results in automation. Command failures throw; do not rely on `$LASTEXITCODE` or parse friendly console output.

When direct Terraform debugging is necessary, keep its flags consistent with the authoring engine and return to the `avm` command for final validation.
