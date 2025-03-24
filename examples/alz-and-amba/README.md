<!-- BEGIN_TF_DOCS -->
# Deploy both ALZ and AMBA with Custom Lib

This example demonstrates how to deploy both ALZ and AMBA archetypes with the use of a custom library.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include both archetypes
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      path = "platform/alz",
      ref  = "2025.02.0"
    },
    {
      path = "platform/amba",
      ref  = "2025.02.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz" {
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

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_maintenance_configuration.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/maintenance_configuration) (resource)
- [azurerm_resource_group.update_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz"></a> [alz](#module\_alz)
### <a name="module_amba"></a> [amba](#module\_amba)

Source: ../../

Version:

<!-- END_TF_DOCS -->