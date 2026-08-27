---
description: " Azure Verified Modules (AVM) and Terraform"
applyTo: "**/*.terraform, **/*.tf, **/*.tfvars, **/*.tfstate, **/*.tflint.hcl, **/*.tf.json, **/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

This repository uses Azure Verified Modules (AVM) for Terraform.
For detailed module guidance, use the [AVM Terraform agent](.github/agents/avm-tf.agent.md) and load only the relevant skills under [.github/skills](.github/skills/).

## AVM Specifications

The authoritative source for every AVM rule (Bicep, Terraform, shared) is the spec index:

- **Index of all specs and docs (raw markdown URLs):** `https://azure.github.io/Azure-Verified-Modules/llms.txt`
- **Rendered docs site:** `https://azure.github.io/Azure-Verified-Modules/`

When a spec ID is mentioned (e.g. `TFFR3`, `RMFR4`, `SNFR1`), fetch `llms.txt` once, look up the raw markdown URL for that ID, and read the current text. Do not cite a spec from memory.

## Terraform Provider Requirement

Managed authoring for a new AVM Terraform module repository MUST use `Azure/azapi` for every control-plane resource and every operation supported by `azapi_data_plane_resource`, `azapi_resource`, `azapi_resource_action`, or `azapi_update_resource`. Do not declare or configure `hashicorp/azurerm`, and do not create any `azurerm_*` resource or data source, for convenience or for ordinary module and supporting infrastructure.

This default prohibition applies everywhere in the repository: the root implementation, submodules, examples, E2E configurations, `.tftest.hcl` files, fixtures, setup or teardown Terraform, migration examples, documentation examples, and generated snippets. Each standalone Terraform root that needs direct Azure resources MUST declare `Azure/azapi` in `required_providers`.

When an example, test, fixture, or E2E setup needs an Azure resource that is not supplied through the module under test, create or read it with `azapi_resource`, `azapi_data_plane_resource`, `azapi_resource_action`, `azapi_update_resource`, or an AzAPI data source as appropriate. Do not use AzureRM as test scaffolding.

`hashicorp/azurerm ~> 4.0` is permitted only when required for a data-plane or other non-ARM operation that genuinely cannot be implemented with any applicable AzAPI resource or action. Each `azurerm_*` resource or data-source block MUST independently satisfy the exception: scope the block to one specific unsupported operation, add the prescribed `provider_azurerm_disallowed` TFLint exclusion, and document the exact block, why AzAPI cannot implement it, and the upstream AzAPI issue or pull request. Replace each block when AzAPI support ships. One valid block does not authorize any other AzureRM use. Examples, E2E configurations, and tests may configure or exercise AzureRM only when required by their independently justified exception blocks; all supporting control-plane resources still use AzAPI.

The migration skill may inspect an existing AzureRM module and refer to legacy `azurerm_*` state addresses as source input. Generated target implementation, examples, tests, fixtures, setup, and documentation follow the same AzAPI-first rule and narrow data-plane/non-ARM exception.

## Module Discovery

- **Terraform Registry**: Search for "avm" + resource name, filter by "Partner" tag
- **Terraform Resource Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/`
- **Terraform Pattern Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/`

## New Module Naming Conventions

- **Resource Modules**: `Azure/avm-res-{service}-{resource}/azure`
- **Pattern Modules**: `Azure/avm-ptn-{pattern}/azure`
- **Utility Modules**: `Azure/avm-utl-{utility}/azure`
- Use kebab-case for services and resources
- Follow Azure service names (e.g., `storage-storageaccount`, `network-virtualnetwork`)

Existing modules can retain legacy `terraform-azurerm-avm-*` repository names and `/azurerm` Registry namespaces. Those names are publication identifiers, not provider declarations, and do not permit generated code to use `hashicorp/azurerm` or `azurerm_*` outside the narrow unsupported data-plane/non-ARM exception.

## Module Usage

When using AVM modules:

1. Pin to a specific version: `version = "1.2.3"`
2. Map enable telemetry to root variable: `enable_telemetry = var.enable_telemetry`
3. For providers, use pessimistic constraints: `version = "~> 1.0"`
4. Start from official examples in the module documentation
5. Replace `source = "../../"` with the registry source when copying examples

## Module Sources

- **Registry for new modules**: `https://registry.terraform.io/modules/Azure/{module}/azure/latest`
- **GitHub for new modules**: `https://github.com/Azure/terraform-azure-avm-{type}-{service}-{resource}`
- **Versions API**: `https://registry.terraform.io/v1/modules/Azure/{module}/[azurerm|azure]/versions`
