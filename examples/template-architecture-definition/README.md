<!-- BEGIN_TF_DOCS -->
# Custom architecture with templating

This example shows how to generate the architecture definition using templating.

Instructions for use:

1. In the `./lib` directory, run terraform init & terraform apply, supplying the value for `var.prefix` when prompted.
2. Observe the generated `custom.alz_architecture_definition.json` file
3. In this example directory, run terraform init & terraform apply, this will use the generated architecture definition to create the resources with the prefix applied to the management group name and display name.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2024.07.3"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.16)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0, >= 2.0.1)

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