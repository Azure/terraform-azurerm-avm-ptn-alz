<!-- BEGIN_TF_DOCS -->
# ALZ Terraform Module

> ⚠️ ***Warning*** ⚠️ This module is currently in development and is not yet ready for use. It should be considered experimental and is subject to change.

This repository contains an early prototype of a new Terraform module for deploying Azure Landing Zones (ALZs).

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_alz"></a> [alz](#provider\_alz)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)

## Modules

No modules.

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_base_archetype"></a> [base\_archetype](#input\_base\_archetype)

Description: The archetype of the management group.  
This should be one of the built in archetypes, or a custom one defined in one of the `lib_dirs`.

Type: `string`

### <a name="input_default_location"></a> [default\_location](#input\_default\_location)

Description: The default location for resources in this management group. Used for policy managed identities.

Type: `string`

### <a name="input_display_name"></a> [display\_name](#input\_display\_name)

Description: The display name of the management group.

Type: `string`

### <a name="input_id"></a> [id](#input\_id)

Description: The id of the management group. This must be unique and cannot be changed after creation.

Type: `string`

### <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id)

Description: The id of the parent management group. Use the tenant id to create a child of the tenant root group.  
The `azurerm_client_config` data source from the AzureRM provider is useful to get the tenant id.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_default_log_analytics_workspace_id"></a> [default\_log\_analytics\_workspace\_id](#input\_default\_log\_analytics\_workspace\_id)

Description: n/a

Type: `string`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: n/a

Type:

```hcl
map(object({
    role_definition_id   = optional(string, "")
    role_definition_name = optional(string, "")
    principal_id         = string
    description          = optional(string, null)
  }))
```

Default: `{}`

## Resources

The following resources are used by this module:

- [azurerm_management_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group) (resource)
- [azurerm_management_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_assignment) (resource)
- [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) (resource)
- [azurerm_policy_set_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition) (resource)
- [azurerm_role_assignment.policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) (resource)
- [alz_archetype.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype) (data source)
- [alz_archetype_keys.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype_keys) (data source)

## Outputs

No outputs.

<!-- markdownlint-enable -->
## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
<!-- END_TF_DOCS -->