---
description: " Azure Verified Modules (AVM) and Terraform"
applyTo: "**/*.terraform, **/*.tf, **/*.tfvars, **/*.tfstate, **/*.hcl, **/*.rego, **/*.tf.json, **/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

The authoritative repository instructions are [`.github/copilot-instructions.md`](.github/copilot-instructions.md). Read that file completely before analyzing or modifying this repository, then load the relevant skill from `.github/skills`.

Use the [AVM Terraform agent](.github/agents/avm-tf.agent.md) for specification-driven module development. When these instructions conflict with a current published AVM specification, the specification takes precedence.

## Safety-critical fallback

- Fetch <https://azure.github.io/Azure-Verified-Modules/llms.txt> and read the current raw page for every relevant specification. Do not cite AVM requirements from memory.
- New AVM Terraform modules use `Azure/azapi` for every control-plane resource and every supported direct Azure operation. Do not use `hashicorp/azurerm` for convenience, supporting infrastructure, examples, tests, or fixtures.
- Permit AzureRM only for a specifically documented data-plane or non-ARM operation that AzAPI cannot perform. Independently justify each block and follow `avm-tf-azapi` and `avm-tf-tflint`.
- Do not hand-edit generated `README.md` files. Edit `_header.md` and `_footer.md`, then use `avm docs` or `avm pre-commit`.
- Use PowerShell 7.4 or later and `Avm.Authoring`; do not substitute retired Make, Porch, container, or repository-launcher workflows.
- Run the smallest relevant test tier, run `avm pre-commit`, commit the complete worktree, then run `avm pr-check`.

The canonical file contains the complete module discovery, tooling, quality, and skill index guidance. Do not duplicate or independently extend those sections here.
