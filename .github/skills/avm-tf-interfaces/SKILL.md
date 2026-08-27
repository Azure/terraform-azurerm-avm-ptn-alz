---
name: avm-tf-interfaces
description: Use for AVM Terraform diagnostic settings, role assignments, locks, managed identities, private endpoints, customer-managed keys, tags, and AzAPI control interfaces.
---

# AVM Terraform Interfaces

Read the current RMFR4, RMFR5, TFFR6, TFFR7, TFFR8, and TFNFR38 pages through <https://azure.github.io/Azure-Verified-Modules/llms.txt>.

Every new module MUST use AzAPI for its primary resource and every directly authored standard-interface or supporting control-plane Azure resource. Do not use AzureRM for convenience in implementation, examples, tests, fixtures, E2E setup, or generated snippets. Each permitted `azurerm_*` resource or data-source block must independently implement one specific unsupported data-plane/non-ARM operation, document the exact block and AzAPI gap with an upstream AzAPI issue or pull request, and be replaced when support ships. One valid block does not authorize another.

## Canonical utility module

For every RMFR4 or RMFR5 interface migration, fetch both current sources from `Azure/Azure-Verified-Modules`:

- `https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/content/specs-defs/specs/terraform/interfaces.md`
- the matching `https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/refs/heads/main/docs/static/includes/interfaces/tf/int.<interface>.schema.tf`

Treat the entire canonical variable declaration as atomic. Copy it in full and replace only documented placeholders; preserve attribute ordering, types, defaults, nullability, descriptions, validations, and error messages exactly. Lint notices are migration hints, not complete implementation instructions.

The resource module declares the exact consumer-facing schema. `Azure/avm-utl-interfaces/azure` provides the implementation and composition:

```hcl
module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "~> 0.6"

  diagnostic_settings_v2 = var.diagnostic_settings
  managed_identities     = var.managed_identities
}
```

Only pass inputs supported by the resource. Keep the utility version constraint current with the specification and Registry release.

## Resource-feature interfaces

Expose an interface only when the Azure resource supports the capability:

| Interface | Consumer variable | Purpose |
| --- | --- | --- |
| Diagnostic settings | `diagnostic_settings` | Route logs and metrics to supported destinations. |
| Role assignments | `role_assignments` | Create RBAC assignments scoped to the resource. |
| Locks | `lock` | Apply an optional `CanNotDelete` or `ReadOnly` management lock. |
| Managed identities | `managed_identities` | Configure system-assigned and user-assigned identities. |
| Private endpoints | `private_endpoints` | Create private endpoints and optional DNS-zone integration. |
| Customer-managed key | `customer_managed_key` | Configure supported CMK encryption. |
| Tags | `tags` | Apply tags to resources that support them. |

Do not expose a no-op interface or rename a standard variable.

## Diagnostic settings v2

New modules use:

- utility input `diagnostic_settings_v2`; and
- utility output `diagnostic_settings_azapi_v2`.

The v2 shape supports log category or category group, metrics, enabled flags, and retention policy objects. Do not restrict category values because Azure can add categories.

The owning module supplies scope and all TFFR4-TFFR8 controls:

```hcl
resource "azapi_resource" "diagnostic_settings" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi_v2

  type      = var.resource_types.insights_diagnostic_settings
  name      = each.value.name
  parent_id = azapi_resource.this.id
  body      = each.value.body

  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  replace_triggers_refs  = []
  response_export_values = []
  retry                  = var.retry

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

Do not use the utility module's legacy diagnostic-settings input or output in new code.

## AzAPI control interfaces

These apply to every AzAPI resource, independently of optional resource features:

### `resource_types`

The object contains one deterministic key per AzAPI resource and nested objects matching submodules. Each owning module defines its own tested API-version defaults. Parent slots do not repeat child string defaults.

### `retry` and `timeouts`

Expose the TFFR7 object shapes. Apply both to every AzAPI resource and cascade them unchanged to every submodule:

```hcl
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
```

### `ignore_body_changes`

Expose one `optional(list(string), [])` field per owned AzAPI resource and one nested child-shaped object per submodule. Apply the matching field and collapse an empty list to `null`:

```hcl
ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
```

Pass only the matching nested slot to a child. Do not cascade the parent's path list unchanged because paths are specific to one resource body.

Paths use body-relative dot notation. Individual list indices cannot be targeted. Ignored configuration is not sent to Azure until the path is removed, and interface changes take effect only after apply.

## Resource ID validation

Validate standard interface resource IDs with TFNFR38 where each field has one expected resource type:

```hcl
validation {
  condition = alltrue([
    for endpoint in values(var.private_endpoints) :
    can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", endpoint.subnet_resource_id))
  ])
  error_message = "Each subnet_resource_id must be a valid subnet resource ID."
}
```

Handle nullable values and collections explicitly. If a field legitimately accepts unrelated resource types, do not validate it against one arbitrary type.

## Composition rules

- Implement locks, role assignments, diagnostic settings, private endpoints, and other child or extension resources as distinct, descriptively named resources or required submodules.
- Keep the primary resource label `this`.
- Source every AzAPI `type` from `var.resource_types`.
- Apply `response_export_values`, `replace_triggers_refs`, `retry`, `timeouts`, and `ignore_body_changes` to every AzAPI resource.
- Use unquoted lifecycle references such as `ignore_changes = [name]`.
- Do not create destination workspaces, virtual networks, subnets, key vaults, or other consumer-owned dependencies inside a resource module.
- Keep standard collection inputs non-null with empty defaults.

Consult the canonical schema files for exact consumer-facing declarations and the `Azure/avm-utl-interfaces/azure` release documentation for implementation inputs and outputs. Do not reconstruct either from memory.
