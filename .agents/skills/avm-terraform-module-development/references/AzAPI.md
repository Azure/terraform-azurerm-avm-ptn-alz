# AzAPI Provider

AVM Terraform modules implement Azure resources with the **AzAPI provider** (`Azure/azapi`). This is required by `TFFR3`. The only legitimate reason to fall back to `azurerm` is when AzAPI has no equivalent resource or data source for the capability you need — when that happens, leave a short comment in the code explaining why, and prefer an `azurerm` *data source* over an `azurerm` *resource* where possible.

Look up the current text of `TFFR3` (and the rationale for AzAPI-first) via `https://azure.github.io/Azure-Verified-Modules/llms.txt`.

## Provider configuration

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0, < 3.0"
    }
  }
}
```

## Resource pattern

AzAPI resources use ARM resource types with explicit API versions. The primary resource **MUST** be named `this` (TFRMNFR2):

```hcl
resource "azapi_resource" "this" {
  type      = var.resource_types.this   # TFFR6 — sourced from `resource_types`, never hard-coded
  parent_id = var.parent_id             # TFRMFR1 — single fully-qualified ARM ID, validated via parse_resource_id
  name      = var.name
  location  = var.location

  body = {
    properties = {
      # Resource-specific properties as an HCL object (not a JSON string).
    }
  }

  # TFFR5 — MUST be specified. List body paths that force replacement on change.
  # `name` and `location` already trigger replacement and don't need to be listed.
  replace_triggers_refs = [
    # "properties.<field-that-forces-replace>",
  ]

  # TFFR4 — MUST be specified, even if empty.
  response_export_values = [
    # "properties.<field>",
  ]

  # TFFR7 — Standard AVM `retry` interface; assigned directly because `retry` is an attribute.
  retry = var.retry

  # TFFR7 — Standard AVM `timeouts` interface. `timeouts` is a block, not an attribute,
  # so a dynamic block is required to honour the variable's `null` default.
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

Satellite resources (locks, role assignments, diagnostic settings, private endpoints, etc.) **MUST NOT** be named `this`; they are named after what they represent (`azapi_resource.lock`, `azapi_resource.role_assignments`, `azapi_resource.diagnostic_settings`, ...). See [interfaces.md](./interfaces.md) for the wiring via `Azure/avm-utl-interfaces/azure`.

### Key attributes

| Attribute                   | Description                                                                                          |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `type`                      | ARM resource type with API version (e.g. `Microsoft.Storage/storageAccounts@2023-01-01`). **MUST** be sourced from `var.resource_types.<key>` — TFFR6 |
| `parent_id`                 | Fully-qualified ARM ID of the parent scope. Assigned from `var.parent_id` — TFRMFR1                  |
| `name`                      | Resource name                                                                                        |
| `location`                  | Azure region                                                                                         |
| `body`                      | Resource properties as an **HCL object** (not a JSON string)                                         |
| `replace_triggers_refs`     | Body paths that should force replacement when changed. **MUST** be specified, even if `[]` — TFFR5    |
| `response_export_values`    | List or map of ARM property paths to export. **MUST** be specified, even if `[]` — TFFR4              |
| `retry`                     | AVM `retry` interface attribute. MUST be wired from `var.retry` on every `azapi_resource` — TFFR7    |
| `timeouts`                  | AVM `timeouts` interface block. MUST be emitted via a `dynamic "timeouts"` block from `var.timeouts` — TFFR7 |
| `locks`                     | Mutex. List of resource IDs to lock on to prevent concurrent operations                              |

### Child resources

Implement subresources of the primary resource (ARM child resource types like `Microsoft.Example/widgets/parts`) as **submodules** under `modules/<singular-name>/`, per `TFRMNFR1`. Do not nest them inside the parent `body` and do not declare them inline in the parent module. Each submodule is a full AVM module with its own `this` primary resource, `parent_id`, `variables.tf`, `outputs.tf`, `terraform.tf`, `_header.md`, `_footer.md`, and tests.

The parent typically wires submodules like this (using `for_each` for cardinality — a submodule's own primary resource **MUST NOT** use `count` or `for_each`):

```hcl
module "part" {
  source   = "./modules/part"
  for_each = var.parts

  name           = each.value.name
  parent_id      = azapi_resource.this.id
  resource_types = { this = var.resource_types.part }
  retry          = var.retry
  timeouts       = var.timeouts
}
```

Satellite extension resources of the primary (locks, role assignments, diagnostic settings, private endpoints) are declared as separate `azapi_resource` blocks driven by the standard interface inputs and the `Azure/avm-utl-interfaces/azure` utility module — see [interfaces.md](./interfaces.md).

### Accessing outputs

Use `.output` to access exported values:

```hcl
azapi_resource.this.output.properties.principalId
```

## Parent ID (`parent_id`)

`TFRMFR1` requires every resource module to expose its parent scope as a single string variable named `parent_id`, and to assign it to the `parent_id` argument of every primary `azapi_resource` it manages. The same rule applies to every submodule.

### Variable declaration

```hcl
variable "parent_id" {
  type     = string
  nullable = false

  validation {
    # TFNFR38 — validate with the AzAPI provider's parse_resource_id function.
    # Replace `Microsoft.Resources/resourceGroups` with the parent resource type
    # expected by this module's primary resource (e.g.
    # `Microsoft.Network/virtualNetworks` for a subnet module). MUST be a literal
    # string, not a reference to another variable.
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }

  description = <<DESCRIPTION
The fully-qualified ARM resource ID of the scope into which the resource managed
by this module will be deployed. This module **does not** create the parent scope.
DESCRIPTION
}
```

### Rules

- **MUST NOT** accept `resource_group_name`, `resource_group_resource_id`, or any other parent-scope-specific variable. The fully-qualified ARM ID supplied via `parent_id` is sufficient and works uniformly for every kind of Azure resource scope (subscription, management group, resource group, parent ARM resource).
- **MUST NOT** create the parent scope inside the module (supersedes the Terraform clause of `RMFR3`).
- Submodules also expose `parent_id`; the parent module typically passes `parent_id = azapi_resource.this.id` to each child.
- The expected parent type passed to `parse_resource_id` **MUST** be a literal string. Hand-rolled `regex`, `startswith`, or `length` checks are not allowed.

### Extension-resource exception

Modules whose primary resource is an Azure extension resource (`Microsoft.Authorization/locks`, `Microsoft.Authorization/roleAssignments`, `Microsoft.Insights/diagnosticSettings`, `Microsoft.Resources/tags`, etc.) attach to any parent type and **MUST NOT** use the `parse_resource_id` validation. They use a generic check instead, and document the exception in the README:

```hcl
validation {
  condition     = length(var.parent_id) > 0 && (startswith(var.parent_id, "/subscriptions/") || startswith(var.parent_id, "/providers/"))
  error_message = "`parent_id` must be a fully-qualified ARM resource ID starting with `/subscriptions/` or `/providers/`."
}
```

## Data sources

```hcl
# Get current client context (subscription, tenant)
data "azapi_client_config" "current" {}

# Use in expressions:
data.azapi_client_config.current.subscription_id
data.azapi_client_config.current.subscription_resource_id
data.azapi_client_config.current.tenant_id
```

## Unit test mocking

```hcl
mock_provider "azapi" {}
```

## Retry and timeouts

`retry` and `timeouts` are standard AVM Terraform interfaces (`TFFR7`; see also [`interfaces.md`](./interfaces.md) and the [Terraform Interfaces spec](https://azure.github.io/Azure-Verified-Modules/specs/tf/interfaces/)). Both **MUST** be applied to every `azapi_resource` the module declares — root resource and submodules — and **MUST** be cascaded unchanged into every submodule the parent instantiates.

### `retry` variable

```hcl
variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module
(root resource and all submodules). Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) Regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry>.
DESCRIPTION
}
```

`retry` is an **attribute** on `azapi_resource`, so it is assigned directly: `retry = var.retry`.

### `timeouts` variable

```hcl
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the
module. Defaults to `null` (provider defaults). Each value is a Go duration
string (e.g. `30m`, `1h`).
DESCRIPTION
}
```

`timeouts` is a **block** on `azapi_resource` (not an attribute), so a `dynamic "timeouts"` block is required to honour the `null` default — see the resource pattern above.

### Module-level defaults

Module owners **MAY** ship sensible defaults (for example, longer create/delete timeouts for slow-provisioning resources). To do so, set the variable's overall `default` to `{}` (not `null`) and provide per-field defaults inside the `optional(...)` wrappers. Consumers **MUST** still be able to override any individual field.

### Cascading to submodules

```hcl
module "child" {
  source = "./modules/child"

  retry    = var.retry
  timeouts = var.timeouts
  # ...other arguments...
}
```

Submodules **MUST** declare their own `retry` and `timeouts` variables with the same schemas and apply them to their own `azapi_resource` blocks (`TFFR7` / `TFRMNFR1`).

## Sensitive attributes

- Passwords, keys, and other secrets are passed via the `sensitive_body` attribute. This object is merged with `body` at runtime.
- All sensitive values **must** be ephemeral.
- Use `sensitive_body_version` (a map) to track which JSON properties came from `sensitive_body` so Terraform can detect changes, e.g. `sensitive_body_version = { "properties.key1" = "1" }`.
- Reference each sensitive body version as a variable.

## Azure resource schema lookup

Use the `Get-AzureSchema.ps1` CLI to query resource type schemas, properties, constraints, and available API versions. This is the source of truth for the correct `type` value and `body` structure on an `azapi_resource`. The script requires PowerShell 7+ (cross-platform) and emits JSON to stdout.

Script location: `.agents/skills/avm-terraform-module-development/scripts/Get-AzureSchema.ps1`

### Workflow

1. **Find the API versions** for the resource type:

   ```powershell
   .agents/skills/avm-terraform-module-development/scripts/Get-AzureSchema.ps1 versions Microsoft.Storage/storageAccounts
   ```

2. **Get the schema** for the resource type at a specific API version:

   ```powershell
   .agents/skills/avm-terraform-module-development/scripts/Get-AzureSchema.ps1 get Microsoft.Storage/storageAccounts 2023-01-01
   ```

3. **Map the schema into the `body`** of your `azapi_resource`:
   - Properties flagged `Required` (Bicep type flag `1`) must be included.
   - Properties flagged `ReadOnly` (flag `2`) must NOT be in `body` — read them via `response_export_values` instead.
   - Properties flagged `WriteOnly` (flag `4`) belong in `sensitive_body`.

4. **Limit depth** when the schema is large:

   ```powershell
   # Shallow (top-level only)
   .agents/skills/avm-terraform-module-development/scripts/Get-AzureSchema.ps1 get Microsoft.Storage/storageAccounts 2023-01-01 -Depth 2

   # Deep (default is 5)
   .agents/skills/avm-terraform-module-development/scripts/Get-AzureSchema.ps1 get Microsoft.Storage/storageAccounts 2023-01-01 -Depth 8
   ```

The script caches the bicep-types-az index under `$HOME/.cache/azure-schema/` with a 24-hour TTL on the index file; per-resource type files are cached indefinitely.
