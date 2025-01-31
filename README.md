<!-- BEGIN_TF_DOCS -->
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module

- This repository contains a Terraform module for deploying Azure Landing Zones (ALZs).
- Make sure to review the examples.

> [!IMPORTANT]
> Make sure to add `.alzlib` to your `.gitignore` file to avoid committing the downloaded ALZ library to your repository.

## Features

- Deploy management groups according to the supplied architecture (default is ALZ)
- Deploy policy assets (definitions, assignments, and initiatives) according to the supplied architecture ands associated archetypes
- Modify policy assignments:
  - Enforcement mode
  - Identity
  - Non-compliance messages
  - Overrides
  - Parameters
  - Resource selectors
- Create the required role assignments for Azure Policy, including support for the **assign permissions** metadata tag, just like the Azure Portal
- Deploy custom role definitions

## AzAPI Provider

We use the AzAPI provider to interact with the Azure APIs.
The new features allow us to be more efficient and reliable, with orders of magnitude speed improvements and retry logic for transient errors.

## Unknown Values & Depends On

This module uses the ALZ Terraform provider. This uses a data source which **must** be read prior to creating the plan.

The `depends_on` feature is therefore not supported in the ALZ provider.
Please do not add a `depends_on` attribute to the module declaration.

Similarly, if you pass an unknown (known after apply) value into the module, it will not be able to read the data source until the plan is being applied.
This may cause resources to be unnecessarily recreated.

To work around this, we have two features.
Firstly we have a `dependencies` variable.
This variable is used to ensure that policies and policy role assignments do not get created until dependent resources are available.

Secondly, for values that are passed into the module, use string interpolation or provider functions to create the required. For example:

### Using `var.dependencies`

This variable is used as a workaround for the lack of support for `depends_on` in the ALZ provider.
Place values into this variable to ensure that policies and policy role assignments do not get created until dependent resources are available.
See the variable documentation and the examples (private DNS and management) for more information.

### Using Provider Functions

Either: Use known values as inputs, or use Terraform Stacks.

> [!NOTE]
> We assume that all variable inputs are literals.

```terraform
locals {
  subscription_id     = data.azapi_client_config.current.subscription_id
  resource_group_name = "rg1"
  resource_type       = "Microsoft.Network/virtualNetworks"
  resource_names      = ["vnet1"]
  my_resource_id = provider::azapi::resource_group_resource_id(
    data.azapi_client_config.current.subscription_id,
    local.resource_group_name,
    local.resource_type,
    local.resource_names
  )
}

module "example" {
  source = "Azure/terraform-azurerm-avm-ptn-alz/azurerm"

  policy_assignments_to_modify = {
    alzroot = {
      policy_assignments = {
        mypolicy = {
          parameters = {
            parameterName = jsonencode({ value = local.my_resource_id })
          }
        }
      }
    }
  }
}
```

### Deferred Actions

We are awaiting the results of the upstream Terraform language experiment *deferred actions*.
This will provide a solution to this issue.
See the release notes [here](https://github.com/hashicorp/terraform/releases/tag/v1.10.0-alpha20241023) for more information.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_alz"></a> [alz](#requirement\_alz) (~> 0.17)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.2)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.9)

## Resources

The following resources are used by this module:

- [azapi_resource.hierarchy_settings](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_0](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_1](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_2](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_3](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_4](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_5](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.management_groups_level_6](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.policy_assignments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.policy_definitions](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.policy_role_assignments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.policy_set_definitions](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.role_definitions](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.subscription_placement](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_update_resource.hierarchy_settings](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [terraform_data.policy_assignments_dependencies](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [terraform_data.policy_role_assignments_dependencies](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [time_sleep.after_management_groups](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.after_policy_definitions](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.after_policy_set_definitions](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [alz_architecture.this](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/architecture) (data source)
- [alz_metadata.telemetry](https://registry.terraform.io/providers/azure/alz/latest/docs/data-sources/metadata) (data source)
- [azapi_client_config.hierarchy_settings](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_architecture_name"></a> [architecture\_name](#input\_architecture\_name)

Description: The name of the architecture to create. This needs to be of the `*.alz_architecture_definition.[json|yaml|yml]` files.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: The default location for resources in this management group. Used for policy managed identities.

Type: `string`

### <a name="input_parent_resource_id"></a> [parent\_resource\_id](#input\_parent\_resource\_id)

Description: The resource name of the parent management group. Use the tenant id to create a child of the tenant root group.  
The `azurerm_client_config`/`azapi_client_config` data sources are able to retrieve the tenant id.  
Do not include the `/providers/Microsoft.Management/managementGroups/` prefix.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_delays"></a> [delays](#input\_delays)

Description: DEPRECATED: Please use the new `retries` variable instead to allow the provider to retry on certain errors.

A map of delays to apply to the creation and destruction of resources.  
Included to work around some race conditions in Azure.

Type:

```hcl
object({
    after_management_group = optional(object({
      create  = optional(string, "0s")
      destroy = optional(string, "0s")
    }), {})
    after_policy_definitions = optional(object({
      create  = optional(string, "0s")
      destroy = optional(string, "0s")
    }), {})
    after_policy_set_definitions = optional(object({
      create  = optional(string, "0s")
      destroy = optional(string, "0s")
    }), {})
  })
```

Default: `{}`

### <a name="input_dependencies"></a> [dependencies](#input\_dependencies)

Description: Place dependent values into this variable to ensure that resources are created in the correct order.  
Ensure that the values placed here are computed/known after apply, e.g. the resource ids.

This is necessary as the unknown values and `depends_on` are not supported by this module as we use the alz provider.  
See the "Unknown Values & Depends On" section above for more information.

e.g.

```hcl
dependencies = {
  policy_role_assignments = [
    module.dependency_example1.output,
    module.dependency_example2.output,
  ]
}
```

Type:

```hcl
object({
    policy_role_assignments = optional(any, null)
    policy_assignments      = optional(any, null)
  })
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_management_group_hierarchy_settings"></a> [management\_group\_hierarchy\_settings](#input\_management\_group\_hierarchy\_settings)

Description: Set this value to configure the hierarchy settings. Options are:

- `default_management_group_name` - (Required) The name of the default management group.
- `require_authorization_for_group_creation` - (Optional) By default, all Entra security principals can create new management groups. When enabled, security principals must have management group write access to create new management groups. Defaults to `true`.
- `update_existing` - (Optional) Update existing hierarchy settings rather than create new. Defaults to `false`.

Type:

```hcl
object({
    default_management_group_name            = string
    require_authorization_for_group_creation = optional(bool, true)
    update_existing                          = optional(bool, false)
  })
```

Default: `null`

### <a name="input_override_policy_definition_parameter_assign_permissions_set"></a> [override\_policy\_definition\_parameter\_assign\_permissions\_set](#input\_override\_policy\_definition\_parameter\_assign\_permissions\_set)

Description: This list of objects allows you to set the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.  
This allows you to correct policies that haven't been authored correctly and means that the provider can generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to set the assignPermissions property for.

The default value has been populated with the Azure Landing Zones policies that are assigned by default, but do not have the correct parameter metadata.

Type:

```hcl
set(object({
    definition_name = string
    parameter_name  = string
  }))
```

Default:

```json
[
  {
    "definition_name": "04754ef9-9ae3-4477-bf17-86ef50026304",
    "parameter_name": "userWorkspaceResourceId"
  },
  {
    "definition_name": "09963c90-6ee7-4215-8d26-1cc660a1682f",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "09a1f130-7697-42bc-8d84-8a9ea17e5192",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "0b026355-49cb-467b-8ac4-f777874e175a",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "1142b015-2bd7-41e0-8645-a531afe09a1e",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "1e5ed725-f16c-478b-bd4b-7bfa2f7940b9",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "2227e1f1-23dd-4c3a-85a9-7024a401d8b2",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "34804460-d88b-4922-a7ca-537165e060e",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "4485d24b-a9d3-4206-b691-1fad83bc5007",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "4ec38ebc-381f-45ee-81a4-acbc4be878f8",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "516187d4-ef64-4a1b-ad6b-a7348502976c",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "56d0ed2b-60fc-44bf-af81-a78c851b5fe1",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "59c3d93f-900b-4827-a8bd-562e7b956e7c",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "637125fd-7c39-4b94-bb0a-d331faf333a9",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "63d03cbd-47fd-4ee1-8a1c-9ddf07303de0",
    "parameter_name": "userWorkspaceResourceId"
  },
  {
    "definition_name": "6a4e6f44-f2af-4082-9702-033c9e88b9f8",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "6dd01e4f-1be1-4e80-9d0b-d109e04cb064",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "7590a335-57cf-4c95-babd-ecbc8fafeb1f",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "7a860e27-9ca2-4fc6-822d-c2d248c300df",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "86cd96e1-1745-420d-94d4-d3f2fe415aa4",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "8fd85785-1547-4a4a-bf90-d5483c9571c5",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "9427df23-0f42-4e1e-bf99-a6133d841c4a",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "942bd215-1a66-44be-af65-6a1c0318dbe2",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "98569e20-8f32-4f31-bf34-0e91590ae9d3",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "a63cc0bd-cda4-4178-b705-37dc439d3e0f",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "aaa64d2d-2fa3-45e5-b332-0b031b9b30e8",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "ad1eeff9-20d7-4c82-a04e-903acab0bfc1",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "ae8a10e6-19d6-44a3-a02d-a2bdfc707742",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "b0e86710-7fb7-4a6c-a064-32e9b829509e",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "b318f84a-b872-429b-ac6d-a01b96814452",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "b6faa975-0add-4f35-8d1c-70bba45c4424",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "b73e81f3-6303-48ad-9822-b69fc00c15ef",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "baf19753-7502-405f-8745-370519b20483",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "c99ce9c1-ced7-4c3e-aca0-10e69ce0cb02",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "d367bd60-64ca-4364-98ea-276775bddd94",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "d389df0a-e0d7-4607-833c-75a6fdac2c2d",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "d627d7c6-ded5-481a-8f2e-7e16b1e6faf6",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "ddca0ddc-4e9d-4bbb-92a1-f7c4dd7ef7ce",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "e016b22b-e0eb-436d-8fd7-160c4eaed6e2",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "ed66d4f5-8220-45dc-ab4a-20d1749c74e6",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "ee40564d-486e-4f68-a5ca-7a621edae0fb",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "ef9fe2ce-a588-4edd-829c-6247069dcfdb",
    "parameter_name": "dcrResourceId"
  },
  {
    "definition_name": "f0fcf93c-c063-4071-9668-c47474bd3564",
    "parameter_name": "privateDnsZoneId"
  },
  {
    "definition_name": "f91991d1-5383-4c95-8ee5-5ac423dd8bb1",
    "parameter_name": "userAssignedIdentityResourceId"
  },
  {
    "definition_name": "fbc14a67-53e4-4932-abcc-2049c6706009",
    "parameter_name": "privateDnsZoneId"
  }
]
```

### <a name="input_override_policy_definition_parameter_assign_permissions_unset"></a> [override\_policy\_definition\_parameter\_assign\_permissions\_unset](#input\_override\_policy\_definition\_parameter\_assign\_permissions\_unset)

Description: This list of objects allows you to unset the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.  
This allows you to correct policies that haven't been authored correctly, or prevent permissions being assigned for policies that are disabled in a policy set. The provider can then generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to unset the assignPermissions property for.

Type:

```hcl
set(object({
    definition_name = string
    parameter_name  = string
  }))
```

Default: `null`

### <a name="input_partner_id"></a> [partner\_id](#input\_partner\_id)

Description: A value to be included in the telemetry tag. Requires the `enable_telemetry` variable to be set to `true`. The must be in the following format:

`<PARTNER_ID_UUID>:<PARTNER_DATA_UUID>`

e.g.

`00000000-0000-0000-0000-000000000000:00000000-0000-0000-0000-000000000000`

Type: `string`

Default: `null`

### <a name="input_policy_assignments_to_modify"></a> [policy\_assignments\_to\_modify](#input\_policy\_assignments\_to\_modify)

Description: A map of policy assignment objects to modify the ALZ architecture with.  
You only need to specify the properties you want to change.

The key is the id of the management group. The value is an object with a single attribute, `policy_assignments`.  
The `policy_assignments` value is a map of policy assignments to modify.  
The key of this map is the assignment name, and the value is an object with optional attributes for modifying the policy assignments.

- `enforcement_mode` - (Optional) The enforcement mode of the policy assignment. Possible values are `Default` and `DoNotEnforce`.
- `identity` - (Optional) The identity of the policy assignment. Possible values are `SystemAssigned` and `UserAssigned`.
- `identity_ids` - (Optional) A set of ids of the user assigned identities to assign to the policy assignment.
- `non_compliance_message` - (Optional) A set of non compliance message objects to use for the policy assignment. Each object has the following properties:
  - `message` - (Required) The non compliance message.
  - `policy_definition_reference_id` - (Optional) The reference id of the policy definition to use for the non compliance message.
- `parameters` - (Optional) The parameters to use for the policy assignment. The map key is the parameter name and the value is an JSON object containing a single `Value` attribute with the values to apply. This to mitigate issues with the Terraform type system. E.g. `{ defaultName = jsonencode({Value = \"value\"}) }`.
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
    policy_assignments = map(object({
      enforcement_mode = optional(string, null)
      identity         = optional(string, null)
      identity_ids     = optional(list(string), null)
      parameters       = optional(map(string), null)
      non_compliance_messages = optional(set(object({
        message                        = string
        policy_definition_reference_id = optional(string, null)
      })), null)
      resource_selectors = optional(list(object({
        name = string
        resource_selector_selectors = optional(list(object({
          kind   = string
          in     = optional(set(string), null)
          not_in = optional(set(string), null)
        })), [])
      })))
      overrides = optional(list(object({
        kind  = string
        value = string
        override_selectors = optional(list(object({
          kind   = string
          in     = optional(set(string), null)
          not_in = optional(set(string), null)
        })), [])
      })))
    }))
  }))
```

Default: `{}`

### <a name="input_policy_default_values"></a> [policy\_default\_values](#input\_policy\_default\_values)

Description: A map of default values to apply to policy assignments. The key is the default name as defined in the library, and the value is an JSON object containing a single `value` attribute with the values to apply. This to mitigate issues with the Terraform type system. E.g. `{ defaultName = jsonencode({ value = \"value\"}) }`

Type: `map(string)`

Default: `null`

### <a name="input_retries"></a> [retries](#input\_retries)

Description: The retry settings to apply to the CRUD operations. Value is a nested object, the top level keys are the resources and the values are an object with the following attributes:

- `error_message_regex` - (Optional) A list of error message regexes to retry on. Defaults to `null`, which will will disable retries. Specify a value to enable.
- `interval_seconds` - (Optional) The initial interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `max_interval_seconds` - (Optional) The maximum interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `multiplier` - (Optional) The multiplier to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value.
- `randomization_factor` - (Optional) The randomization factor to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value.

For more information please see the provider documentation here: <https://registry.terraform.io/providers/Azure/azapi/azurerm/latest/docs/resources/resource#nestedatt--retry>

Type:

```hcl
object({
    management_groups = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "Permission to Microsoft.Management/managementGroups on resources of type 'Write' is required on the management group or its ancestors."
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    role_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_set_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_assignments = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed",                                                      # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "The policy definition specified in policy assignment '.+' is out of scope" # If assignment is created soon after a policy definition has been created then the assignment will fail with this error.
      ])
      interval_seconds     = optional(number, 5)
      max_interval_seconds = optional(number, 30)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_role_assignments = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "ResourceNotFound",    # If the resource has just been created, retry until it is available.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    hierarchy_settings = optional(object({
      error_message_regex  = optional(list(string), null)
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    subscription_placement = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
  })
```

Default: `{}`

### <a name="input_subscription_placement"></a> [subscription\_placement](#input\_subscription\_placement)

Description: A map of subscriptions to place into management groups. The key is deliberately arbitrary to avoid issues with known after apply values. The value is an object:

- `subscription_id` - (Required) The id of the subscription to place in the management group.
- `management_group_name` - (Required) The name of the management group to place the subscription in.

Type:

```hcl
map(object({
    subscription_id       = string
    management_group_name = string
  }))
```

Default: `{}`

### <a name="input_timeouts"></a> [timeouts](#input\_timeouts)

Description: A map of timeouts to apply to the creation and destruction of resources.  
If using retry, the maximum elapsed retry time is governed by this value.

The object has attributes for each resource type, with the following optional attributes:

- `create` - (Optional) The timeout for creating the resource. Defaults to `5m` apart from policy assignments, where this is set to `15m`.
- `delete` - (Optional) The timeout for deleting the resource. Defaults to `5m`.
- `update` - (Optional) The timeout for updating the resource. Defaults to `5m`.
- `read` - (Optional) The timeout for reading the resource. Defaults to `5m`.

Each time duration is parsed using this function: <https://pkg.go.dev/time#ParseDuration>.

Type:

```hcl
object({
    management_group = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    role_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_set_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_assignment = optional(object({
      create = optional(string, "15m") # Set high to allow consolidation of policy definitions coming into scope
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_role_assignment = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
  })
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_management_group_resource_ids"></a> [management\_group\_resource\_ids](#output\_management\_group\_resource\_ids)

Description: A map of management group names to their resource ids.

### <a name="output_policy_assignment_identity_ids"></a> [policy\_assignment\_identity\_ids](#output\_policy\_assignment\_identity\_ids)

Description: A map of policy assignment names to their identity ids.

### <a name="output_policy_assignment_resource_ids"></a> [policy\_assignment\_resource\_ids](#output\_policy\_assignment\_resource\_ids)

Description: A map of policy assignment names to their resource ids.

### <a name="output_policy_definition_resource_ids"></a> [policy\_definition\_resource\_ids](#output\_policy\_definition\_resource\_ids)

Description: A map of policy definition names to their resource ids.

### <a name="output_policy_role_assignment_resource_ids"></a> [policy\_role\_assignment\_resource\_ids](#output\_policy\_role\_assignment\_resource\_ids)

Description: A map of policy role assignments to their resource ids.

### <a name="output_policy_set_definition_resource_ids"></a> [policy\_set\_definition\_resource\_ids](#output\_policy\_set\_definition\_resource\_ids)

Description: A map of policy set definition names to their resource ids.

### <a name="output_role_definition_resource_ids"></a> [role\_definition\_resource\_ids](#output\_role\_definition\_resource\_ids)

Description: A map of role definition names to their resource ids.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->