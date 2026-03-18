---
description: " Azure Verified Modules (AVM) and Terraform"
applyTo: "**/*.terraform, **/*.tf, **/*.tfvars, **/*.tfstate, **/*.tflint.hcl, **/*.tf.json, **/*.tfvars.json"
---

# Azure Verified Modules (AVM) Terraform

This repository uses Azure Verified Modules (AVM) for Terraform.
For detailed guidance on module development, refer to the [AVM-Terraform-Development skill](.agents/skills/AVM-Terraform-Development/SKILL.md).

## Module Discovery

- **Terraform Registry**: Search for "avm" + resource name, filter by "Partner" tag
- **Terraform Resource Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/`
- **Terraform Pattern Modules Index**: `https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/`

## Module Naming Conventions

- **Resource Modules**: `Azure/avm-res-{service}-{resource}/azurerm`
- **Pattern Modules**: `Azure/avm-ptn-{pattern}/azurerm`
- **Utility Modules**: `Azure/avm-utl-{utility}/azurerm`
- Use kebab-case for services and resources
- Follow Azure service names (e.g., `storage-storageaccount`, `network-virtualnetwork`)

## Module Usage

When using AVM modules:

1. Pin to a specific version: `version = "1.2.3"`
2. Map enable telemetry to root variable: `enable_telemetry = var.enable_telemetry`
3. For providers, use pessimistic constraints: `version = "~> 1.0"`
4. Start from official examples in the module documentation
5. Replace `source = "../../"` with the registry source when copying examples

## Module Sources

- **Registry**: `https://registry.terraform.io/modules/Azure/{module}/azurerm/latest`
- **GitHub**: `https://github.com/Azure/terraform-azurerm-avm-{type}-{service}-{resource}`
- **Versions API**: `https://registry.terraform.io/v1/modules/Azure/{module}/[azurerm|azure]/versions`
