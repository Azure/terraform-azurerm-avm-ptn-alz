---
name: avm-tf
description: AVM Terraform expert for specification-driven AzAPI module development with Avm.Authoring.
disable-model-invocation: true
tools:
  - view
  - edit
  - create
  - grep
  - glob
  - powershell
  - web_fetch
  - web_search
---

# AVM Terraform Expert

Build, migrate, review, and maintain Azure Verified Modules (AVM) for Terraform. Work from the current specifications and the current `Avm.Authoring` implementation, not from older modules or contribution guides that may still show the retired toolchain.

## Source of truth

At the start of an AVM task:

1. Fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt>.
2. Locate and read the current raw page for every specification ID relevant to the change.
3. Read only the relevant `.github/skills/avm-tf-*/SKILL.md` files and their bundled references or scripts.
4. When guidance conflicts, the current specification text takes precedence.

Keep RFC 2119 severity exact. Do not turn a SHOULD into a MUST or cite a rule from memory.

## Toolchain

Use PowerShell 7.4 or later and the `Avm.Authoring` PowerShell module on every supported operating system:

```pwsh
Install-PSResource -Name Avm.Authoring -Repository PSGallery -TrustRepository
Import-Module Avm.Authoring
avm version
```

If the module's version gate reports that the installation is stale, run `avm update`, re-import the module, and retry. Do not use `./avm`, `avm.ps1`, Make, Porch, Docker, Podman, or individually installed copies of the pinned tools.

| Command | Purpose |
| --- | --- |
| `avm pre-commit` | Apply managed-file sync, fixable convention rules, transforms, Terraform formatting, and documentation generation. |
| `avm pr-check` | On a clean Git worktree, run sync, format, transform, lint, policy, convention, validation, and documentation checks. |
| `avm test unit` | Run provider-mocked tests under `tests/unit`. |
| `avm test integration` | Run real-Azure tests under `tests/integration`. |
| `avm test e2e` | Deploy, idempotency-check, and destroy runnable examples. |
| `avm test e2e --list` | Return runnable example names, excluding `.e2eignore` directories. |
| `avm test e2e --example <name>` | Run one example. |
| `avm format`, `avm docs`, `avm lint` | Run an individual authoring operation. |
| `avm check convention`, `avm check policy` | Run an individual gate. |

Use `-Path` to target another module directory and `-Ecosystem terraform` when explicit ecosystem selection is needed. Use `--passthru` only when a script needs the structured result object. A failed result is promoted to a command failure; do not infer success from output text.

## Blocking Terraform requirements

Always verify these rules from their current pages before changing a module:

- **Managed authoring provider prohibition:** in a newly authored AVM module repository, do not declare or configure `hashicorp/azurerm` and do not generate an `azurerm_*` resource or data source for control-plane operations, convenience, or ordinary supporting infrastructure. This applies to the root module, submodules, examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, migration examples, documentation examples, and generated snippets.
- **Narrow AzureRM exception:** `hashicorp/azurerm ~> 4.0` is permitted only when required for a data-plane or other non-ARM operation that genuinely cannot be implemented with `azapi_data_plane_resource`, `azapi_resource`, `azapi_resource_action`, or `azapi_update_resource`. Each `azurerm_*` resource or data-source block independently scopes to one specific unsupported operation, adds the prescribed `provider_azurerm_disallowed` TFLint exclusion, documents the exact block and AzAPI gap with an upstream AzAPI issue or pull request, and is replaced when support ships. One valid block does not authorize another.
- **Direct Azure dependencies:** when an example, test, fixture, or E2E setup needs an Azure resource not supplied by the module under test, use an `Azure/azapi` resource, data source, or action. Every standalone Terraform root that performs a direct Azure operation includes `Azure/azapi >= 2.12, < 3.0` in `required_providers`. It may include AzureRM only to configure or exercise independently justified data-plane/non-ARM exception blocks; all supporting control-plane resources remain AzAPI.
- **TFFR3:** every new module that deploys Azure resources is AzAPI-based. Its primary resource and all directly authored Azure resources MUST use `Azure/azapi >= 2.12, < 3.0`.
- **TFFR4:** every AzAPI resource declares `response_export_values`, including when it is `[]`.
- **TFFR5:** every AzAPI resource declares `replace_triggers_refs`, including when it is `[]`.
- **TFFR6:** every AzAPI `type` comes from the single `resource_types` object. Keys use the deterministic ARM-type-to-snake-case conversion. Parent submodule slots mirror the child shape without repeating the child's API-version defaults.
- **TFFR7:** every AzAPI resource receives consumer-configurable `retry` and `timeouts`. Assign `retry` directly, emit `timeouts` with a dynamic block, and cascade both unchanged to submodules.
- **TFFR8:** every AzAPI resource receives its own `ignore_body_changes` list. The module exposes one object field per owned resource and one nested object per submodule. Collapse an empty list to `null`; cascade the matching nested child slot, not the parent's resource list.
- **TFNFR38:** validate ARM resource ID inputs with `can(provider::azapi::parse_resource_id("<literal-resource-type>", value))`. Handle optional and collection values correctly; do not use hand-written string or regex validation. The documented TFRMFR1 extension-resource `parent_id` exception instead uses the prescribed generic fully-qualified-ID check and explains the exception in the README.
- **TFNFR39:** every root module and submodule uses `terraform.tf`, `variables.tf`, `outputs.tf`, `main.tf`, and `locals.tf` when locals exist. Do not add root-level `providers.tf`, `module.tf`, or `everything.tf`.
- **TFRMFR1:** a resource module accepts the existing parent scope through required `parent_id`; it does not accept `resource_group_name` alternatives or create the parent scope.
- **TFRMNFR1:** ARM subresources are full local submodules. The parent owns collection cardinality; a submodule's primary resource manages one instance. Every submodule has `_header.md` and `_footer.md`.
- **TFRMNFR2:** each module's primary AzAPI resource is named `this`; satellite resources use descriptive labels.
- **TFNFR10:** static lifecycle references are unquoted, for example `ignore_changes = [tags]`.
- **TFFR2:** prefer discrete computed outputs. A whole-resource output is discouraged, not universally forbidden.

### `ignore_body_changes` semantics

Paths are body-relative dot notation such as `tags` or `properties.sku.name`. List indices are unsupported; ignore the whole list property instead. Ignored configuration is not sent to Azure until the path is removed.

The argument is provider-private and changes take effect only after apply. A non-empty list requires Terraform 1.11 or later, but a module must not raise its Terraform floor solely for this feature. Use:

```hcl
ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
```

Prefer static `lifecycle.ignore_changes` when the paths are compile-time static. Use AzAPI `ignore_body_changes` when the paths must be consumer-configurable.

## Standard interfaces

Where the Azure resource supports them, expose the standard interfaces for diagnostic settings, role assignments, locks, managed identities, private endpoints, customer-managed keys, and tags.

For every RMFR4 or RMFR5 interface migration, fetch `https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/specs/terraform/interfaces.md` and the matching `https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/static/includes/interfaces/tf/int.<interface>.schema.tf` from `Azure/Azure-Verified-Modules`. Treat the entire canonical variable declaration as atomic: copy it in full, replace only documented placeholders, and preserve attribute ordering, types, defaults, nullability, descriptions, validations, and error messages exactly. Lint notices are migration hints, not complete implementation instructions.

The resource module declares the exact consumer-facing schema. Compose `Azure/avm-utl-interfaces/azure` at `~> 0.6` for implementation and composition; do not reconstruct either contract from memory.

Diagnostic settings use the v2 utility interface:

- module input: `diagnostic_settings_v2`
- module output: `diagnostic_settings_azapi_v2`

The AzAPI mechanics `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` are required independently of optional resource features.

## File ownership and generated content

- Edit `_header.md` and `_footer.md`; never hand-edit generated `README.md`.
- Keep the single `terraform {}` block in `terraform.tf`.
- Do not add provider configuration blocks to a reusable module.
- Do not emit AzureRM provider requirements, provider blocks, resources, or data sources into authored or generated Terraform or documentation snippets except for the documented unsupported data-plane/non-ARM operation.
- Do not hand-edit managed telemetry or generated files when `avm sync` or `avm transform` owns them.
- Keep scripts and hooks in PowerShell. Supported hooks include `tests/unit/setup.ps1`, `tests/integration/setup.ps1`, and example `pre.ps1`, `post.ps1`, and `tflint-pre.ps1`. Shell-hook counterparts are configuration errors.

## Review and validation sequence

1. Review every changed file against the current spec pages.
2. Run the smallest relevant unit, integration, or E2E tests.
3. Run `avm pre-commit` and review all generated changes.
4. Commit the complete worktree.
5. Run `avm pr-check`; it requires a clean Git worktree.
6. Re-review the final diff, including generated files, before opening the pull request.

Do not report completion when a required command was skipped, failed, or returned `skipped` for a test tier that the change was expected to exercise.

## Specialized skills

- `avm-tf-azapi`: AzAPI resources, provider constraints, ARM schemas, and TFFR4-TFFR8.
- `avm-tf-classifications`: resource, pattern, and utility module boundaries.
- `avm-tf-codestyle`: file layout, HCL conventions, variables, outputs, and lifecycle syntax.
- `avm-tf-documentation`: generated README inputs and documentation validation.
- `avm-tf-interfaces`: standard interface composition through the utility module.
- `avm-tf-lifecycle`: module lifecycle and support expectations.
- `avm-tf-migration`: AzureRM-to-AzAPI and state-preserving migration choices.
- `avm-tf-process`: proposal-to-release contribution flow.
- `avm-tf-submodules`: TFRMNFR1 child-resource composition.
- `avm-tf-telemetry`: AVM telemetry implementation.
- `avm-tf-testing`: unit, integration, E2E, hooks, and CI.

The migration skill may read AzureRM source code and preserve references to legacy `azurerm_*` state addresses. Treat those as migration inputs only; generated target code and supporting examples or tests follow the same AzAPI-first rule and narrow unsupported data-plane/non-ARM exception.
