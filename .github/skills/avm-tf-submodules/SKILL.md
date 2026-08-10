---
name: avm-tf-submodules
description: Use for AVM Terraform ARM subresources implemented as local submodules, including cardinality, parent_id, resource_types, retry, timeouts, ignore_body_changes, outputs, files, and tests.
---

# AVM Terraform Submodules

TFRMNFR1 requires each ARM subresource to be implemented as a full local submodule under `modules/<singular-name>/`. Read TFRMNFR1 together with TFRMFR1, TFRMNFR2, TFFR6-TFFR8, TFNFR38, and TFNFR39 through <https://azure.github.io/Azure-Verified-Modules/llms.txt>.

## Cardinality

The parent owns `for_each` or `count`; the child primary resource owns one instance:

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

```hcl
# modules/part/main.tf
resource "azapi_resource" "this" {
  type      = var.resource_types.example_widgets_parts
  name      = var.name
  parent_id = var.parent_id

  body = {
    properties = var.properties
  }

  ignore_body_changes    = length(var.ignore_body_changes.example_widgets_parts) > 0 ? var.ignore_body_changes.example_widgets_parts : null
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

Do not add `count` or `for_each` to the child's primary resource.

## Required files

Every submodule follows TFNFR39 and the applicable documentation, telemetry, and testing requirements:

```text
modules/part/
  _footer.md
  _header.md
  main.tf
  main.telemetry.tf
  outputs.tf
  README.md          # generated
  terraform.tf
  variables.tf
  locals.tf        # when locals exist
  tests/
    unit/
    integration/
```

Additional files use canonical prefixes such as `main.role_assignments.tf`. The submodule declares every provider it consumes in its own `terraform.tf`.

## Parent ID

Each submodule exposes required, non-null `parent_id` and assigns it to its primary resource:

```hcl
variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the existing widget that will contain the part."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Example/widgets", var.parent_id))
    error_message = "`parent_id` must be a valid widget resource ID."
  }
}
```

The parent normally passes `azapi_resource.this.id`. Do not replace this contract with `resource_group_name`, subscription IDs, or data-source reconstruction.

## `resource_types`

The child owns its tested API-version default:

```hcl
# modules/part/variables.tf
variable "resource_types" {
  type = object({
    example_widgets_parts = optional(string, "Microsoft.Example/widgets/parts@2024-01-01")
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the part submodule.

- `example_widgets_parts` - Resource type and API version for the part.
DESCRIPTION
}
```

The parent mirrors the complete child shape but does not repeat child string defaults:

```hcl
variable "resource_types" {
  type = object({
    example_widgets = optional(string, "Microsoft.Example/widgets@2024-01-01")

    example_widgets_parts = optional(object({
      example_widgets_parts = optional(string)
    }), {})
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `example_widgets` - Resource type and API version for the widget.
- `example_widgets_parts` - Resource-type overrides passed to the part submodule.
- `example_widgets_parts.example_widgets_parts` - Resource type and API-version override for the part.
DESCRIPTION
}
```

Pass `var.resource_types.example_widgets_parts` unchanged to the child.
Document every owned-resource field and every nested submodule field in each variable description.

## `retry` and `timeouts`

The parent cascades these resource-agnostic TFFR7 values unchanged. The child declares the same schemas and applies them to every AzAPI resource it owns.

Do not hard-code retry or timeout values that consumers cannot override.

## `ignore_body_changes`

Paths are specific to one resource body, so the parent exposes a child-shaped nested slot:

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
Body-relative paths ignored for root and part resources. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure.

- `example_widgets` - Paths ignored on the widget resource.
- `example_widgets_parts` - Paths passed to the part submodule.
- `example_widgets_parts.example_widgets_parts` - Paths ignored on the part resource.
DESCRIPTION
}
```

The child's variable contains its own field:

```hcl
variable "ignore_body_changes" {
  type = object({
    example_widgets_parts = optional(list(string), [])
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
Body-relative paths ignored on the part resource. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure.

- `example_widgets_parts` - Paths ignored on the part resource.
DESCRIPTION
}
```

Pass the nested slot unchanged. Do not pass the parent's `example_widgets` list to the child.

## Outputs

The single-instance child exposes a scalar resource ID:

```hcl
output "resource_id" {
  value       = azapi_resource.this.id
  description = "The resource ID of the part."
}
```

The parent aggregates naturally from the `for_each` module call:

```hcl
output "part_resource_ids" {
  value       = { for key, part in module.part : key => part.resource_id }
  description = "A map of part resource IDs keyed by the input map."
}
```

Prefer discrete outputs over whole-resource output objects.

## Documentation and tests

- Author `_header.md` and `_footer.md`; generate each `README.md` with `avm docs` or `avm pre-commit`.
- Add provider-mocked unit tests for child logic and parent aggregation.
- Add real-Azure integration coverage where ARM behavior matters.
- Exercise representative child instances through an E2E example.
- Verify parent and child resource IDs, nested interface propagation, and idempotency.

## Migration warning

Extracting an existing root collection into a `for_each` submodule changes addresses from `resource.type["key"]` to `module.child["key"].resource.this`. A generic reusable moved block cannot preserve arbitrary consumer keys across that resource-to-module boundary.

Prefer an in-place provider migration first, or publish explicit state migration steps and classify the extraction as breaking when required. See `avm-tf-migration`.
