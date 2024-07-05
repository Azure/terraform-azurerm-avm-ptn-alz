<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = "uksouth"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.10)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi)

## Resources

The following resources are used by this module:

- [azapi_client_config.current](https://registry.terraform.io/providers/hashicorp/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz_architecture"></a> [alz\_architecture](#module\_alz\_architecture)

Source: ../../

Version:

<!-- END_TF_DOCS -->