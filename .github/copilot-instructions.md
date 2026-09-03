---
description: Instructions for developing and maintaining Azure Verified Modules for Terraform.
---

# Azure Verified Modules (AVM) - Terraform Instructions

## Overview

This repository contains an Azure Verified Module for Terraform. AVM modules are reusable, tested Azure infrastructure modules that follow the published AVM specifications.

AVM has three module classifications:

- **Resource modules** - one primary Azure resource and its child or extension resources.
- **Pattern modules** - opinionated multi-resource solutions composed from resource modules.
- **Utility modules** - shared logic or interfaces that do not directly deploy an Azure resource.

Use the [AVM Terraform agent](agents/avm-tf.agent.md) for specification-driven module development. `AGENTS.md` is a compatibility entry point for agents that do not load this Copilot-specific file directly.

## Critical Compliance Requirements

### Instruction acknowledgement

After reading these instructions and the relevant skills, but before modifying files, output this block visibly to the user:

```json
{
  "avm-terraform-instructions": "loaded",
  "skills": ["<loaded-skill-name>"]
}
```

List every skill loaded for the task. Use an empty `skills` array when no specialized skill applies.

### Follow current AVM specifications

Before reviewing or generating Terraform:

1. Fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt>.
2. Locate and read the current raw page for every relevant Terraform and shared specification.
3. Read the complete skill matching the task.
4. Resolve conflicts in favor of the current published specification.

Do not cite a specification from memory or treat an older module as authoritative.

### Use AzAPI for managed authoring

New AVM Terraform modules use `Azure/azapi` for every control-plane resource and every supported direct Azure operation. Do not use `hashicorp/azurerm` for convenience, ordinary supporting infrastructure, examples, tests, or fixtures.

AzureRM is permitted only for a specifically documented data-plane or non-ARM operation that AzAPI cannot perform. Each exception must be independently justified and must not authorize other AzureRM usage. Read `avm-tf-azapi` and `avm-tf-tflint` before implementing an exception.

### Generate documentation

Do not hand-edit generated `README.md` files. Author module content in `_header.md` and `_footer.md`, then run `avm docs` or `avm pre-commit`. Read `avm-tf-documentation` before changing module documentation.

## Use the Managed Toolchain

Use PowerShell 7.4 or later with `Avm.Authoring`:

```pwsh
Install-PSResource -Name Avm.Authoring -Repository PSGallery -TrustRepository
Import-Module Avm.Authoring
avm version
```

| Command | Purpose |
| --- | --- |
| `avm pre-commit` | Synchronize managed files, apply fixable conventions and transforms, format Terraform, and generate documentation. |
| `avm pr-check` | Run the clean-worktree pull request validation gate. |
| `avm test unit` | Run provider-mocked Terraform tests. |
| `avm test integration` | Run real-Azure integration tests. |
| `avm test e2e` | Deploy, idempotency-check, and destroy runnable examples. |
| `avm lint` | Run the managed TFLint configuration. |
| `avm check policy` | Evaluate example plans against APRL and AVMSEC through Conftest. |

If the version gate reports that `Avm.Authoring` is stale, run `avm update`, re-import the module, and retry. Do not substitute the retired Make, Porch, container, or repository-launcher workflows.

## Module Discovery

Use the current AVM indexes to confirm module availability, classification, naming, and ownership:

- [Terraform resource modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
- [Terraform pattern modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/)
- [Terraform utility modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-utility-modules/)

New repositories use `terraform-azure-avm-<class>-<name>` and publish under the `Azure` Terraform Registry namespace with the `/azure` system identifier. Existing legacy repository and Registry names do not permit AzureRM use.

## Quality Assurance

- Keep reusable modules free of provider configuration blocks.
- Use PowerShell for supported hooks and scripts.
- Add or update the smallest relevant unit, integration, or E2E coverage.
- Run `avm pre-commit` and review generated changes.
- Commit the complete worktree before running `avm pr-check`.
- Treat TFLint and Conftest exceptions as reviewed deviations, not shortcuts around a failing check.

## Skills

When a task falls within a skill's domain, read and follow the full skill before proceeding.

| Skill | Use for | File |
| --- | --- | --- |
| `avm-tf-azapi` | AzAPI resources, ARM schemas, provider constraints, retries, timeouts, response exports, replacement triggers, and `ignore_body_changes`. | `.github/skills/avm-tf-azapi/SKILL.md` |
| `avm-tf-classifications` | Resource, pattern, and utility module classification and naming. | `.github/skills/avm-tf-classifications/SKILL.md` |
| `avm-tf-codestyle` | Terraform file layout, HCL style, variables, outputs, validation, and lifecycle syntax. | `.github/skills/avm-tf-codestyle/SKILL.md` |
| `avm-tf-conftest` | Conftest policy findings, APRL and AVMSEC rule identifiers, and example-local Rego exceptions. | `.github/skills/avm-tf-conftest/SKILL.md` |
| `avm-tf-documentation` | Generated README inputs, examples, and documentation validation. | `.github/skills/avm-tf-documentation/SKILL.md` |
| `avm-tf-interfaces` | Standard AVM interfaces and utility-module composition. | `.github/skills/avm-tf-interfaces/SKILL.md` |
| `avm-tf-lifecycle` | Module proposal, ownership, lifecycle, versioning, and deprecation. | `.github/skills/avm-tf-lifecycle/SKILL.md` |
| `avm-tf-migration` | AzureRM-to-AzAPI migration and state-preserving changes. | `.github/skills/avm-tf-migration/SKILL.md` |
| `avm-tf-process` | Contribution flow from repository setup through validation, pull request, and release. | `.github/skills/avm-tf-process/SKILL.md` |
| `avm-tf-submodules` | Child-resource submodule structure and composition. | `.github/skills/avm-tf-submodules/SKILL.md` |
| `avm-tf-telemetry` | AVM telemetry resources, inputs, and AzAPI headers. | `.github/skills/avm-tf-telemetry/SKILL.md` |
| `avm-tf-testing` | Unit, integration, E2E, hooks, and CI testing. | `.github/skills/avm-tf-testing/SKILL.md` |
| `avm-tf-tflint` | Current AVM TFLint rules, canonical rule IDs, severity, overrides, scope, and precedence. | `.github/skills/avm-tf-tflint/SKILL.md` |
