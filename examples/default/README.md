<!-- BEGIN_TF_DOCS -->
<!-- Code generated by terraform-docs. DO NOT EDIT. -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      path = "platform/alz",
      ref  = "2025.02.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source = "../../"

  architecture_name  = "alz"
  location           = "northeurope"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.17)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0, >= 2.0.1)

## Resources

The following resources are used by this module:

- [azapi_client_config.current](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: Enable telemetry for the module.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz_architecture"></a> [alz\_architecture](#module\_alz\_architecture)

Source: ../../

Version:

<!-- END_TF_DOCS -->