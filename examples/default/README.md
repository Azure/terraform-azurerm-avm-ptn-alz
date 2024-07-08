<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.14)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.14)

## Resources

The following resources are used by this module:

- [azapi_client_config.current](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)

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