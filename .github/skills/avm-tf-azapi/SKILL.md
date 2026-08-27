---
name: avm-tf-azapi
description: Use for AVM Terraform AzAPI resources, provider constraints, ARM schemas, parent IDs, resource types, retries, timeouts, response exports, replacement triggers, and ignore_body_changes.
---

# AVM Terraform AzAPI

Read the current TFFR3-TFFR8, TFNFR38, TFRMFR1, TFRMNFR1, and TFRMNFR2 pages through <https://azure.github.io/Azure-Verified-Modules/llms.txt> before implementing or reviewing an AzAPI resource.

## Provider requirements

Every new AVM Terraform module repository that deploys Azure resources MUST use AzAPI for every control-plane resource and every supported direct Azure operation. Do not declare or configure `hashicorp/azurerm`, and do not create any `azurerm_*` resource or data source for convenience or ordinary supporting infrastructure.

This managed-authoring prohibition applies to the root implementation, submodules, examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, migration examples, documentation examples, and generated snippets. When supporting Terraform needs a direct Azure resource that the module under test does not supply, use an AzAPI resource, data source, or action.

TFFR3 requires:

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}
```

`~> 2.12` means `>= 2.12, < 3.0`. The 2.12 floor is required for `ignore_body_changes`.

Every standalone Terraform root that performs a direct Azure operation MUST include `Azure/azapi` in `required_providers`. Use `azapi_resource`, `azapi_data_plane_resource`, `azapi_resource_action`, `azapi_update_resource`, or an AzAPI data source as appropriate. Do not start a new module from an AzureRM implementation and treat migration as future work.

`hashicorp/azurerm ~> 4.0` is permitted only when required for a data-plane or other non-ARM operation that genuinely cannot be implemented with those AzAPI resource forms. Each `azurerm_*` resource or data-source block independently scopes to one specific unsupported operation, adds the prescribed `provider_azurerm_disallowed` TFLint exclusion, documents the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and is replaced when support ships. One valid block does not authorize another. Do not use the exception for any control-plane resource.

## Complete resource pattern

For `Microsoft.Example/widgets`, the deterministic TFFR6 key is `example_widgets`:

```hcl
resource "azapi_resource" "this" {
  type      = var.resource_types.example_widgets
  name      = var.name
  parent_id = var.parent_id
  location  = var.location

  body = {
    properties = {
      skuName = var.sku_name
    }
  }

  ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
  replace_triggers_refs = [
    "properties.skuName",
  ]
  response_export_values = [
    "properties.provisioningState",
  ]
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
```

The primary resource label is `this`. Satellite resources such as locks, role assignments, and diagnostic settings use descriptive labels.

### Required AzAPI arguments

- `type`: always read from `var.resource_types.<deterministic_key>`.
- `response_export_values`: present on every resource, even when empty.
- `replace_triggers_refs`: present on every resource, even when empty.
- `retry`: assigned directly from `var.retry`.
- `timeouts`: emitted with a dynamic block from `var.timeouts`.
- `ignore_body_changes`: read from the field for this specific resource and collapse `[]` to `null`.

The same requirements apply to equivalent AzAPI resource types, not only `azapi_resource`.

## `resource_types`

Drop `Microsoft.`, lowercase the provider token without splitting internal capitals, convert each resource path segment to snake case, and join the tokens with underscores:

| ARM type | Key |
| --- | --- |
| `Microsoft.Example/widgets` | `example_widgets` |
| `Microsoft.Example/widgets/parts` | `example_widgets_parts` |
| `Microsoft.Authorization/roleAssignments` | `authorization_role_assignments` |
| `Microsoft.KeyVault/vaults/secrets` | `keyvault_vaults_secrets` |
| `Microsoft.Network/virtualNetworks/subnets` | `network_virtual_networks_subnets` |

```hcl
variable "resource_types" {
  type = object({
    example_widgets     = optional(string, "Microsoft.Example/widgets@2024-01-01")
    authorization_locks = optional(string, "Microsoft.Authorization/locks@2020-05-01")

    example_widgets_parts = optional(object({
      example_widgets_parts = optional(string)
    }), {})
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `example_widgets` - Resource type and API version for the widget.
- `authorization_locks` - Resource type and API version for locks.
- `example_widgets_parts` - Resource-type overrides passed to the part submodule.
- `example_widgets_parts.example_widgets_parts` - Resource type and API-version override for parts.
DESCRIPTION
}
```

Each module owns the stable API-version defaults for resources it declares. A parent's nested submodule slot mirrors the child variable but does not repeat the child's string defaults.
Document every owned-resource field and every nested submodule field in the variable description.

## `ignore_body_changes`

The shape uses the same keys and module tree as `resource_types`, but each owned resource has a list of body paths:

```hcl
variable "ignore_body_changes" {
  type = object({
    example_widgets = optional(list(string), [])

    example_widgets_parts = optional(object({
      example_widgets_parts = optional(list(string), [])
    }), {})
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure
until the path is removed.

- `example_widgets` - Paths ignored on the widget resource.
- `example_widgets_parts` - Paths passed to the part submodule.
- `example_widgets_parts.example_widgets_parts` - Paths ignored on part resources.
DESCRIPTION
}
```

Rules:

- declare one `optional(list(string), [])` field for each AzAPI resource owned by the module;
- declare one nested object matching each instantiated submodule's full shape;
- pass the nested slot to that submodule unchanged;
- use non-empty body-relative dot paths such as `tags` or `properties.sku.name`;
- do not address individual list indices; ignore the whole list property;
- collapse empty lists to `null`;
- do not raise the Terraform version floor solely for this feature; and
- document that provider-private changes take effect after apply.

Non-empty values require Terraform 1.11 or later. Prefer static `lifecycle.ignore_changes` when the ignored references are compile-time static. Static lifecycle references are unquoted, for example `ignore_changes = [tags]`.

## Parent scope validation

Resource modules accept an existing parent scope through required `parent_id`:

```hcl
variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the existing resource group into which the widget will be deployed."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid resource group resource ID."
  }
}
```

The expected type is a literal string. Apply the same TFNFR38 pattern to every ARM resource ID input, including optional, collection, and nested values. Do not accept `resource_group_name` or construct the parent ID inside a resource module.

Polymorphic inputs that legitimately accept multiple unrelated resource types should not be validated against one arbitrary type. For a general polymorphic input, follow the TFNFR38 exception and leave it without resource-type validation. For an extension-resource module's `parent_id`, follow TFRMFR1 instead: require a non-empty fully-qualified ID beginning with `/subscriptions/` or `/providers/`, and document the exception in the README.

## Submodules

ARM subresources are full local submodules. The parent owns cardinality:

```hcl
module "part" {
  source   = "./modules/part"
  for_each = var.parts

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  resource_types      = var.resource_types.example_widgets_parts
  retry               = var.retry
  timeouts            = var.timeouts
  ignore_body_changes = var.ignore_body_changes.example_widgets_parts
}
```

The child declares one `azapi_resource.this` without `count` or `for_each`.

## Outputs and sensitive data

Export only properties needed by outputs. Prefer discrete computed outputs:

```hcl
output "resource_id" {
  value       = azapi_resource.this.id
  description = "The resource ID of the deployed widget."
}

output "provisioning_state" {
  value       = azapi_resource.this.output.properties.provisioningState
  description = "The provisioning state returned by Azure."
}
```

Put secrets in `sensitive_body`, make secret inputs ephemeral where required by the current specs, and use `sensitive_body_version` to make changes detectable without persisting secret values.

## ARM schema workflow

Use the repository's PowerShell schema helper rather than guessing:

```pwsh
pwsh .github/skills/avm-tf-azapi/scripts/Get-AzureSchema.ps1 versions Microsoft.Example/widgets
pwsh .github/skills/avm-tf-azapi/scripts/Get-AzureSchema.ps1 get Microsoft.Example/widgets 2024-01-01
```

Include required writable properties in `body`, exclude read-only properties, export needed read-only values, and put write-only secret properties in `sensitive_body`. Prefer a stable API version unless the resource or required feature is preview-only.

For Terraform provider schema inspection beyond ARM body schemas, see the [tfpluginschema reference](references/tfpluginschema.md).

## Migration checks

When moving from AzureRM:

1. preserve state addresses with a valid `moved` block or documented state migration;
2. verify the plan has zero unintended destroys or replacements;
3. add `resource_types`, `retry`, `timeouts`, and `ignore_body_changes`;
4. add required response exports and replacement triggers;
5. update outputs from AzureRM attributes to AzAPI output paths;
6. run integration and upgrade-path tests; and
7. run `avm pre-commit`, commit, then run `avm pr-check` on the clean worktree.

AzureRM code and `azurerm_*` addresses are source input for migration only. Do not carry the AzureRM provider, resources, or data sources into generated target implementation, examples, tests, fixtures, setup or teardown Terraform, or documentation snippets unless the target still requires the documented unsupported data-plane/non-ARM operation.
