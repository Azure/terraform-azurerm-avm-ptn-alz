<!-- BEGIN_TF_DOCS -->
# role-assignments

This simplified example shows how to assign roles, both built-in and custom.

Make sure to run the `pre.sh` script before running this example.

```hcl
# This allows us to get the tenant id
data "azapi_client_config" "current" {}

# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "test"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
  management_group_role_assignments = {
    test1 = {
      principal_type             = var.principal_type
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = data.azapi_client_config.current.object_id
      management_group_name      = "${var.prefix}test1"
    }
    test2 = {
      principal_type             = var.principal_type
      role_definition_id_or_name = "Security-Operations (${var.prefix}test2)"
      principal_id               = data.azapi_client_config.current.object_id
      management_group_name      = "${var.prefix}test2"
    }
  }
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

### <a name="input_prefix"></a> [prefix](#input\_prefix)

Description: Management group prefix

Type: `string`

Default: `""`

### <a name="input_principal_type"></a> [principal\_type](#input\_principal\_type)

Description: The principal type to use for the role assignment.

Type: `string`

Default: `"ServicePrincipal"`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_alz_architecture"></a> [alz\_architecture](#module\_alz\_architecture)

Source: ../../

Version:

<!-- END_TF_DOCS -->
