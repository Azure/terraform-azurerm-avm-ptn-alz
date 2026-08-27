---
name: avm-tf-documentation
description: Use for AVM Terraform generated README content, _header.md, _footer.md, examples documentation, terraform-docs inputs, and Avm.Authoring documentation checks.
---

# AVM Terraform Documentation

AVM Terraform `README.md` files are generated. Never edit them directly.

Documentation for every new resource-deploying module MUST describe an AzAPI-first implementation. Authored and generated snippets use AzAPI for all control-plane and ordinary supporting resources and MUST NOT present AzureRM as a convenience alternative.

## Source files

For the root module, every submodule, and every documented example:

- `_header.md` contains authored content before the generated Terraform tables.
- Terraform sources provide requirements, providers, resources, modules, inputs, and outputs.
- `_footer.md` contains authored content after the generated tables, including the required data-collection notice where applicable.
- `README.md` is the generated result committed to Git.

Submodules are full AVM modules and need their own `_header.md`, `_footer.md`, and generated `README.md`.

## Authoring rules

- Explain purpose, important behavior, prerequisites, and supported scenarios in `_header.md`.
- Put interface semantics in variable descriptions so generated input tables stay useful.
- Document every variable field, especially `resource_types`, `retry`, `timeouts`, and `ignore_body_changes`.
- For `ignore_body_changes`, state that paths are body-relative dot notation, ignored configuration is not sent to Azure, and changes take effect only after apply.
- Ensure provider snippets include `Azure/azapi`. Include `hashicorp/azurerm` only for an exact permitted data-plane/non-ARM operation.
- In examples, E2E instructions, Terraform tests, fixtures, and setup or teardown snippets, use AzAPI for direct Azure dependencies not supplied by the module under test.
- For every permitted `azurerm_*` resource or data-source block, independently document the exact block, the specific unsupported data-plane/non-ARM operation, why no applicable AzAPI resource or action can implement it, the upstream AzAPI issue or pull request, and that the block must be replaced when support ships. One documented block does not authorize another.
- Preserve legitimate published AVM module source addresses ending in `/azurerm`; that suffix is a legacy Registry namespace, not an AzureRM provider requirement.
- Prefer working examples over duplicated implementation prose.
- Keep headings and links stable for Terraform Registry rendering.
- Do not explain internal review decisions or migration history in the README unless consumers need that information.

## Generate documentation

Use `Avm.Authoring` from PowerShell 7.4 or later:

```pwsh
Import-Module Avm.Authoring
avm docs
```

`avm pre-commit` also regenerates documentation:

```pwsh
avm pre-commit
```

Review and commit the generated README changes. After the worktree is clean, `avm pr-check` verifies documentation as part of the full PR gauntlet:

```pwsh
avm pr-check
```

Do not run `terraform-docs` directly unless debugging the authoring implementation. Do not use `./avm`, `avm.ps1`, Make, Porch, or a container.

## Descriptions

Descriptions must be precise enough for a consumer to use the input or output without reading the implementation:

```hcl
variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the existing parent scope into which the resource will be deployed."
}

output "resource_id" {
  value       = azapi_resource.this.id
  description = "The resource ID of the deployed resource."
}
```

Use heredocs for structured object documentation. Keep defaults and constraints synchronized with the actual type:

```hcl
variable "ignore_body_changes" {
  type = object({
    example_widgets = optional(list(string), [])
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource. Paths use dot notation
and changes take effect only after apply. Configuration for an ignored path is
not sent to Azure until the path is removed.

- `example_widgets` - Paths ignored on the widget resource.
DESCRIPTION
}
```

## Failure handling

If a generated README is stale:

1. change the Terraform source or authored header/footer that owns the content;
2. run `avm docs` or `avm pre-commit`;
3. inspect the generated diff; and
4. commit the source and generated output together.

Do not patch the generated table to make a check pass.
