<!-- BEGIN_TF_DOCS -->
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module

> ⚠️ ***Warning*** ⚠️ This module is still in development but is ready for initial testing and feedback via [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/issues).

- This repository contains a Terraform module for deploying Azure Landing Zones (ALZs).
- Make sure to review the examples.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.11)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.9)

## Providers

The following providers are used by this module:

- <a name="provider_alz"></a> [alz](#provider\_alz) (~> 0.11)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.74)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.9)

## Resources

The following resources are used by this module:

- [alz_policy_role_assignments.this](https://registry.terraform.io/providers/azure/alz/latest/docs/resources/policy_role_assignments) (resource)
- [azurerm_management_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group) (resource)
- [azurerm_management_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_assignment) (resource)
- [azurerm_management_group_subscription_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_subscription_association) (resource)
- [azurerm_management_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_template_deployment) (resource)
- [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) (resource)
- [azurerm_policy_set_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [time_sleep.before_management_group_creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.before_policy_assignments](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.before_policy_role_assignments](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [alz_archetype.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype) (data source)
- [alz_archetype_keys.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/archetype_keys) (data source)
- [azurerm_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

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

### <a name="input_parent_resource_id"></a> [parent\_resource\_id](#input\_parent\_resource\_id)

Description: The resource id of the parent management group. Use the tenant id to create a child of the tenant root group.  
The `azurerm_client_config` data source from the AzureRM provider is useful to get the tenant id.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_default_log_analytics_workspace_id"></a> [default\_log\_analytics\_workspace\_id](#input\_default\_log\_analytics\_workspace\_id)

Description: The resource id of the default log analytics workspace to use for policy parameters.

Type: `string`

Default: `null`

### <a name="input_default_private_dns_zone_resource_group_id"></a> [default\_private\_dns\_zone\_resource\_group\_id](#input\_default\_private\_dns\_zone\_resource\_group\_id)

Description: Resource group id for the private dns zones to use in policy parameters.

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

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_policy_assignments_to_modify"></a> [policy\_assignments\_to\_modify](#input\_policy\_assignments\_to\_modify)

Description: A map of policy assignment objects to modify the ALZ archetype with.  
You only need to specify the properties you want to change.

The key is the name of the policy assignment.  
The value is a map of the properties of the policy assignment.

- `enforcement_mode` - (Optional) The enforcement mode of the policy assignment. Possible values are `Default` and `DoNotEnforce`.
- `identity` - (Optional) The identity of the policy assignment. Possible values are `SystemAssigned` and `UserAssigned`.
- `identity_ids` - (Optional) A set of ids of the user assigned identities to assign to the policy assignment.
- `non_compliance_message` - (Optional) A set of non compliance message objects to use for the policy assignment. Each object has the following properties:
  - `message` - (Required) The non compliance message.
  - `policy_definition_reference_id` - (Optional) The reference id of the policy definition to use for the non compliance message.
- `parameters` - (Optional) A JSON string of parameters to use for the policy assignment. E.g. `jsonencode({"param1": "value1", "param2": 2})`.
- `resource_selectors` - (Optional) A list of resource selector objects to use for the policy assignment. Each object has the following properties:
  - `name` - (Required) The name of the resource selector.
  - `selectors` - (Optional) A list of selector objects to use for the resource selector. Each object has the following properties:
    - `kind` - (Required) The kind of the selector. Allowed values are: `resourceLocation`, `resourceType`, `resourceWithoutLocation`. `resourceWithoutLocation` cannot be used in the same resource selector as `resourceLocation`.
    - `in` - (Optional) A set of strings to include in the selector.
    - `not_in` - (Optional) A set of strings to exclude from the selector.
- `overrides` - (Optional) A list of override objects to use for the policy assignment. Each object has the following properties:
  - `kind` - (Required) The kind of the override.
  - `value` - (Required) The value of the override. Supported values are policy effects: <https://learn.microsoft.com/azure/governance/policy/concepts/effects>.
  - `selectors` - (Optional) A list of selector objects to use for the override. Each object has the following properties:
    - `kind` - (Required) The kind of the selector.
    - `in` - (Optional) A set of strings to include in the selector.
    - `not_in` - (Optional) A set of strings to exclude from the selector.

Type:

```hcl
map(object({
    enforcement_mode = optional(string, null)
    identity         = optional(string, null)
    identity_ids     = optional(list(string), null)
    parameters       = optional(string, null)
    non_compliance_message = optional(set(object({
      message                        = string
      policy_definition_reference_id = optional(string, null)
    })), null)
    resource_selectors = optional(list(object({
      name = string
      selectors = optional(list(object({
        kind   = string
        in     = optional(set(string), null)
        not_in = optional(set(string), null)
      })), [])
    })))
    overrides = optional(list(object({
      kind  = string
      value = string
      selectors = optional(list(object({
        kind   = string
        in     = optional(set(string), null)
        not_in = optional(set(string), null)
      })), [])
    })))
  }))
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to associated principals and role definitions to the management group.

The key is the your reference for the role assignment. The value is a map of the properties of the role assignment.

- `role_definition_id` - (Optional) The id of the role definition to assign to the principal. Conflicts with `role_definition_name`. `role_definition_id` and `role_definition_name` are mutually exclusive and one of them must be supplied.
- `role_definition_name` - (Optional) The name of the role definition to assign to the principal. Conflicts with `role_definition_id`.
- `principal_id` - (Required) The id of the principal to assign the role definition to.
- `description` - (Optional) The description of the role assignment.

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

### <a name="input_subscription_ids"></a> [subscription\_ids](#input\_subscription\_ids)

Description: A set of subscription ids to move under this management group.

Type: `set(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_management_group_resource_id"></a> [management\_group\_resource\_id](#output\_management\_group\_resource\_id)

Description: The resource id of the created management group.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
