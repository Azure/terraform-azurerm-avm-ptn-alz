<!-- BEGIN_TF_DOCS -->
# ALZ Terraform Module

> ⚠️ ***Warning*** ⚠️ This module is still in development but is ready for initial testing and feedback via [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/issues).

This repository contains Terraform module for deploying Azure Landing Zones (ALZs).
Make sure to review the examples.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (>= 0.5.1)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.74.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (>= 0.9.1)

## Providers

The following providers are used by this module:

- <a name="provider_alz"></a> [alz](#provider\_alz) (>= 0.5.1)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.74.0)

- <a name="provider_time"></a> [time](#provider\_time) (>= 0.9.1)

## Resources

The following resources are used by this module:

- [alz_policy_role_assignments.this](https://registry.terraform.io/providers/azure/alz/latest/docs/resources/policy_role_assignments) (resource)
- [azurerm_management_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group) (resource)
- [azurerm_management_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_assignment) (resource)
- [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) (resource)
- [azurerm_policy_set_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) (resource)
- [time_sleep.before_management_group_creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.before_policy_assignments](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.before_policy_role_assignments](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [alz_archetype.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype) (data source)
- [alz_archetype_keys.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype_keys) (data source)

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

### <a name="input_delays"></a> [delays](#input\_delays)

Description: A map of delays to apply to the creation and destruction of resources.  
Included to work around some race conditions in Azure.

Type:

```hcl
object({
    before_management_group = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }), {})
    before_policy_assignments = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }), {})
    before_policy_role_assignments = optional(object({
      create  = optional(string, "60s")
      destroy = optional(string, "0s")
    }), {})
  })
```

Default: `{}`

### <a name="input_policy_assignments_to_add"></a> [policy\_assignments\_to\_add](#input\_policy\_assignments\_to\_add)

Description: Not implemented yet.

Type: `map(object({}))`

Default: `{}`

### <a name="input_policy_assignments_to_remove"></a> [policy\_assignments\_to\_remove](#input\_policy\_assignments\_to\_remove)

Description: A set of policy assignment names to remove from the `base_archetype`.

Type: `set(string)`

Default: `[]`

### <a name="input_policy_definitions_to_add"></a> [policy\_definitions\_to\_add](#input\_policy\_definitions\_to\_add)

Description: A set of policy definition names to add to the `base_archetype`.  
The definition must exist in one of the loaded lib directories.

Type: `set(string)`

Default: `[]`

### <a name="input_policy_definitions_to_remove"></a> [policy\_definitions\_to\_remove](#input\_policy\_definitions\_to\_remove)

Description: A set of policy definition names to remove from the `base_archetype`.

Type: `set(string)`

Default: `[]`

### <a name="input_policy_set_definitions_to_add"></a> [policy\_set\_definitions\_to\_add](#input\_policy\_set\_definitions\_to\_add)

Description: A set of policy set definition names to add to the `base_archetype`.  
The definition must exist in one of the loaded lib directories.

Type: `set(string)`

Default: `[]`

### <a name="input_policy_set_definitions_to_remove"></a> [policy\_set\_definitions\_to\_remove](#input\_policy\_set\_definitions\_to\_remove)

Description: A set of policy set definition names to remove from the `base_archetype`.

Type: `set(string)`

Default: `[]`

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

### <a name="input_role_definitions_to_add"></a> [role\_definitions\_to\_add](#input\_role\_definitions\_to\_add)

Description: A set of role definition names to add to the `base_archetype`.  
The definition must exist in one of the loaded lib directories.

Type: `set(string)`

Default: `[]`

### <a name="input_role_definitions_to_remove"></a> [role\_definitions\_to\_remove](#input\_role\_definitions\_to\_remove)

Description: A set of role definition names to remove from the `base_archetype`.

Type: `set(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_management_group_name"></a> [management\_group\_name](#output\_management\_group\_name)

Description: The id of the management group.

## Modules

No modules.

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
