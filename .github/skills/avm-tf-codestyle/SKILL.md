---
name: avm-tf-codestyle
description: Use for AVM Terraform file layout, HCL style, variables, outputs, validation, lifecycle syntax, provider requirements, and Avm.Authoring formatting.
---

# AVM Terraform Code Style

Fetch the current Terraform non-functional specifications through <https://azure.github.io/Azure-Verified-Modules/llms.txt>. Current module examples can lag the specification and are not authoritative.

## Standard file layout

TFNFR39 applies to the root module and every submodule:

| File | Requirement | Contents |
| --- | --- | --- |
| `terraform.tf` | MUST | The single `terraform {}` block with required Terraform and provider versions. |
| `variables.tf` | MUST | Variable blocks. |
| `outputs.tf` | MUST | Output blocks. |
| `main.tf` | MUST | Primary resource, data, and module blocks. |
| `locals.tf` | Required when locals exist | Local values only. |

Large modules may use `main.<topic>.tf`, `variables.<topic>.tf`, `outputs.<topic>.tf`, and `locals.<topic>.tf`. Topic names are snake case and each file contains only the block kind indicated by its prefix.

Do not add root-level `providers.tf`, `module.tf`, or `everything.tf`. Reusable AVM modules declare provider requirements but never provider configurations.

Each module and submodule also includes `_header.md` and `_footer.md`; `README.md` is generated.

## Provider requirements

Every new module repository that deploys Azure resources MUST use AzAPI for every control-plane and supported direct Azure operation. Do not declare or configure `hashicorp/azurerm`, and do not create any `azurerm_*` resource or data source for convenience or ordinary supporting infrastructure in implementation, submodules, examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, migration examples, documentation examples, or generated snippets.

TFNFR25 requires a minimum and maximum Terraform CLI constraint, while TFFR3 requires the AzAPI provider range. Use the governance-managed baseline; a compliant current shape is:

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}
```

Apply this `Azure/azapi` requirement to every standalone Terraform root that directly creates, reads, or acts on Azure resources. Supporting resources outside the module under test use AzAPI. Each permitted `azurerm_*` resource or data-source block must independently implement one specific unsupported data-plane/non-ARM operation, document the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and be replaced when support ships. One valid block does not authorize another.

Do not raise `required_version` only because non-empty `ignore_body_changes` needs Terraform 1.11. Emit `null` when that interface is unused so earlier supported Terraform versions remain compatible.

## Naming and declarations

- Use snake case for Terraform identifiers.
- Name the primary AzAPI resource `this`; name satellite resources after their purpose.
- Give every variable and output a precise type and description.
- Mark secret variables and outputs sensitive and follow the current ephemeral-value requirements.
- Default collections to `{}` or `[]` with `nullable = false`.
- Use `optional(...)` for non-required object attributes and give defaults that match the documentation.
- Keep variable, local, resource, module, and output ordering consistent with the transforms applied by `avm transform`.
- Prefer discrete computed outputs over whole-resource outputs.

Example:

```hcl
variable "private_endpoints" {
  type = map(object({
    name               = optional(string)
    subnet_resource_id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for endpoint in values(var.private_endpoints) :
      can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", endpoint.subnet_resource_id))
    ])
    error_message = "Each private endpoint subnet must be a valid subnet resource ID."
  }

  description = "A map of private endpoints to create."
}
```

TFNFR38 requires `provider::azapi::parse_resource_id` with a literal expected resource type for ARM resource IDs. Short-circuit optional values and iterate collections or nested attributes. Do not use `regex`, `startswith`, `length`, or `split` as substitutes, except for the prescribed generic check on an extension-resource module's polymorphic `parent_id` under TFRMFR1.

## AzAPI block requirements

Every AzAPI resource must:

- source `type` from the deterministic field in `var.resource_types`;
- declare `response_export_values`;
- omit `replace_triggers_refs` when no replacement paths exist; otherwise declare a non-empty static list of unique, valid JMESPath body paths;
- assign `retry = var.retry`;
- emit `timeouts` through a dynamic block; and
- assign the per-resource `ignore_body_changes` list, collapsing empty to `null`.
- set `tags = var.tags` exactly on resource types supported by the current AVM TFLint capability snapshot and omit `tags` on unsupported types.

See `avm-tf-azapi` for the complete pattern.

## Lifecycle syntax

Terraform lifecycle references are expressions, not strings:

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

Use static `lifecycle.ignore_changes` for compile-time-static references. Use the consumer-configurable AzAPI `ignore_body_changes` interface when body paths are dynamic. Body paths are strings because they are passed to the provider:

```hcl
ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
```

## Generated and managed files

- Edit `_header.md` or `_footer.md`, not `README.md`.
- Do not hand-edit managed telemetry or provider-version content that `avm sync` or `avm transform` owns.
- Keep comments rare and limited to non-obvious constraints or documented exceptions.

## Formatting and validation

Use the PowerShell module rather than individual binaries:

```pwsh
avm transform
avm format
avm docs
avm pre-commit
```

Review and commit all resulting changes, then run:

```pwsh
avm pr-check
```

`avm pr-check` requires a clean Git worktree. Do not use Make, the old repository launcher, a container, Porch, or a separately installed formatter to approximate these checks.
