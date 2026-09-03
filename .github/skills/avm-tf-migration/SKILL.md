---
name: avm-tf-migration
description: Use for AVM Terraform AzureRM-to-AzAPI migrations, state preservation, moved blocks, provider state moves, submodule extraction, upgrade tests, and post-migration specification compliance.
---

# AVM Terraform Migration

An AzureRM-to-AzAPI migration is complete only when the implementation satisfies the current AVM specifications and existing consumers have a documented, tested state path.

Migration guidance applies to existing modules only. AzureRM may be read, analyzed, and referenced as source input being migrated, including legacy `azurerm_*` state addresses. Generated target code uses AzAPI for every control-plane and supported Azure operation.

The target rule includes implementation, submodules, upgrade examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, documentation examples, and generated snippets. Supporting control-plane resources use AzAPI, and each standalone target Terraform root includes `Azure/azapi` in `required_providers`. Retain an `azurerm_*` resource or data-source block only when that block independently implements one specific unsupported data-plane/non-ARM operation. Document the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and replace the block when support ships. One valid block does not authorize another.

Read TFFR3-TFFR8, TFRMFR1, TFRMNFR1, TFRMNFR2, TFNFR38, and TFNFR39 through <https://azure.github.io/Azure-Verified-Modules/llms.txt> before choosing the migration shape.

## Separate two changes

Treat these as different graph migrations:

1. **Provider migration in place:** `azurerm_*` to an AzAPI resource at the same module/cardinality boundary.
2. **Composition migration:** moving a resource across a module boundary, such as extracting a root collection into `module.child[each.key].azapi_resource.this`.

Combining them makes state preservation harder and can make a reusable `moved` block impossible. Prefer migrating the provider in place first, releasing that state path, and extracting to a submodule in a later breaking release when needed.

## Cardinality rule

TFRMNFR1 requires the parent module to own `count` or `for_each`. A submodule's primary resource manages one instance:

```hcl
module "part" {
  source   = "./modules/part"
  for_each = var.parts
}
```

```hcl
# modules/part/main.tf
resource "azapi_resource" "this" {
  # No count or for_each here.
}
```

Do not move `for_each` inside the submodule to make state addresses easier. That violates the target design.

A root collection address such as:

```text
azurerm_example_part.this["a"]
```

becomes:

```text
module.part["a"].azapi_resource.this
```

Terraform cannot express a generic key-preserving resource-to-module move for every unknown consumer key. Options are:

- migrate the provider at the existing boundary first;
- migrate a resource already inside an existing `for_each` module call;
- publish explicit consumer `terraform state mv` instructions for known keys; or
- accept and document a breaking state migration when extraction itself is required.

Never hide a state-breaking extraction behind a claim that a wildcard `moved` block preserves it.

## Provider migration in place

When the providers support the state move, use a declarative block:

```hcl
moved {
  from = azurerm_example_widget.this
  to   = azapi_resource.this
}
```

For a same-level collection, moving the resource address can preserve its instances. Verify this against applied state; do not assume provider state conversion supports every resource.

Keep migration blocks for the documented compatibility window and release them with clear upgrade notes. Use direct `terraform state mv` only when no reusable declarative move exists, and provide PowerShell-friendly instructions:

```pwsh
terraform state list
terraform state mv 'azurerm_example_part.this["a"]' 'module.part["a"].azapi_resource.this'
```

Back up state before imperative changes.

## Target implementation checklist

The AzAPI target must include:

- `Azure/azapi ~> 2.12`;
- primary resource label `this`;
- required `parent_id` and TFNFR38 resource ID validation;
- standard TFNFR39 files in root and submodules;
- `type` from the deterministic `resource_types` object;
- `response_export_values`, including an explicit empty value;
- `replace_triggers_refs` only when replacement paths exist, using a non-empty static list of unique, valid JMESPath body paths;
- consumer-configurable `retry` and dynamic `timeouts`;
- per-resource `ignore_body_changes` with empty lists collapsed to `null`;
- nested `resource_types` and `ignore_body_changes` slots for submodules;
- discrete outputs mapped from `azapi_resource.this.output`; and
- standard interfaces composed through `Azure/avm-utl-interfaces/azure ~> 0.6`.

Do not retain AzureRM as a convenience fallback or copy it into target examples and tests. Existing AzureRM configuration is migration input only, except when the target still requires the narrowly documented unsupported data-plane/non-ARM operation.

## Ignore semantics during migration

Static Terraform lifecycle references remain expressions:

```hcl
lifecycle {
  ignore_changes = [name]
}
```

Use this for compile-time-static resource attributes, including a migration case where an imported server-assigned role-assignment name must remain stable.

Use TFFR8 `ignore_body_changes` for consumer-selected body paths:

```hcl
ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
```

Paths are body-relative dot notation, cannot target list indices, and prevent ignored configuration from being sent to Azure. A change to the provider-private value takes effect only after apply.

## Upgrade-path validation

Test against real state:

1. deploy a representative example with the latest published pre-migration module;
2. capture `terraform state list` and a state backup;
3. switch the example to the local migrated module;
4. run `terraform init -upgrade`;
5. run `terraform plan` and require zero unintended destroys or replacements;
6. apply the migration;
7. run a second plan and require no changes;
8. verify discrete outputs and all supported interfaces; and
9. destroy through the migrated implementation.

Use `avm test integration` for real-Azure Terraform tests and `avm test e2e --example <name>` for an example deployment. Run `avm pre-commit`, commit all results, and then run `avm pr-check` on a clean worktree.

If state cannot be preserved, classify the change correctly under the current breaking-change and semantic-versioning specifications. Document exact consumer commands and expected effects rather than silently accepting recreation.
