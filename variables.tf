variable "architecture_name" {
  type        = string
  description = <<DESCRIPTION
The name of the architecture to create. This needs to be of the `*.alz_architecture_definition.[json|yaml|yml]` files.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
The default location for resources in this management group. Used for policy managed identities.
DESCRIPTION
  nullable    = false
}

variable "parent_resource_id" {
  type        = string
  description = <<DESCRIPTION
The resource name of the parent management group. Use the tenant id to create a child of the tenant root group.
The `azurerm_client_config`/`azapi_client_config` data sources are able to retrieve the tenant id.
Do not include the `/providers/Microsoft.Management/managementGroups/` prefix.
DESCRIPTION
  nullable    = false

  validation {
    condition     = !strcontains(var.parent_resource_id, "/")
    error_message = "The parent resource id must be the name of the parent management group and should not contain `/`."
  }
  validation {
    condition     = length(var.parent_resource_id) > 0
    error_message = "The parent resource id must not be an empty string."
  }
}

variable "dependencies" {
  type = object({
    policy_role_assignments = optional(any, null)
    policy_assignments      = optional(any, null)
  })
  default     = {}
  description = <<DESCRIPTION
Place dependent values into this variable to ensure that resources are created in the correct order.
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
DESCRIPTION
  nullable    = false
}

variable "management_group_hierarchy_settings" {
  type = object({
    default_management_group_name            = string
    require_authorization_for_group_creation = optional(bool, true)
    update_existing                          = optional(bool, false)
  })
  default     = null
  description = <<DESCRIPTION
Set this value to configure the hierarchy settings. Options are:

- `default_management_group_name` - (Required) The name of the default management group.
- `require_authorization_for_group_creation` - (Optional) By default, all Entra security principals can create new management groups. When enabled, security principals must have management group write access to create new management groups. Defaults to `true`.
- `update_existing` - (Optional) Update existing hierarchy settings rather than create new. Defaults to `false`.
DESCRIPTION

  validation {
    condition     = var.management_group_hierarchy_settings == null ? true : var.management_group_hierarchy_settings.default_management_group_name != ""
    error_message = "The default management group name must not be an empty string."
  }
  validation {
    condition     = var.management_group_hierarchy_settings == null ? true : var.management_group_hierarchy_settings.default_management_group_name != null
    error_message = "The default management group name must not be null."
  }
  validation {
    condition     = var.management_group_hierarchy_settings == null ? true : can(regex("^[a-zA-Z0-9_.()\\-]{1,90}$", var.management_group_hierarchy_settings.default_management_group_name))
    error_message = "Mangement group name must be between 1-90 characters. It must start with a letter or a number, and consist only of alphanumerics, hyphens, underscores, periods, and parentheses."
  }
  validation {
    error_message = "The management group name must not end with a period."
    condition     = var.management_group_hierarchy_settings == null ? true : !can(regex("\\.$", var.management_group_hierarchy_settings.default_management_group_name))
  }
}

variable "override_policy_definition_parameter_assign_permissions_set" {
  type = set(object({
    definition_name = string
    parameter_name  = string
  }))
  default = [
    {
      "definition_name" = "04754ef9-9ae3-4477-bf17-86ef50026304",
      "parameter_name"  = "userWorkspaceResourceId"
    },
    {
      "definition_name" = "09963c90-6ee7-4215-8d26-1cc660a1682f",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "09a1f130-7697-42bc-8d84-8a9ea17e5192",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "0b026355-49cb-467b-8ac4-f777874e175a",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "1142b015-2bd7-41e0-8645-a531afe09a1e",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "1e5ed725-f16c-478b-bd4b-7bfa2f7940b9",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "2227e1f1-23dd-4c3a-85a9-7024a401d8b2",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "34804460-d88b-4922-a7ca-537165e060e",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "4485d24b-a9d3-4206-b691-1fad83bc5007",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "4ec38ebc-381f-45ee-81a4-acbc4be878f8",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "516187d4-ef64-4a1b-ad6b-a7348502976c",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "56d0ed2b-60fc-44bf-af81-a78c851b5fe1",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "59c3d93f-900b-4827-a8bd-562e7b956e7c",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "637125fd-7c39-4b94-bb0a-d331faf333a9",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "63d03cbd-47fd-4ee1-8a1c-9ddf07303de0",
      "parameter_name"  = "userWorkspaceResourceId"
    },
    {
      "definition_name" = "6a4e6f44-f2af-4082-9702-033c9e88b9f8",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "6dd01e4f-1be1-4e80-9d0b-d109e04cb064",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "7590a335-57cf-4c95-babd-ecbc8fafeb1f",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "7a860e27-9ca2-4fc6-822d-c2d248c300df",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "86cd96e1-1745-420d-94d4-d3f2fe415aa4",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "8fd85785-1547-4a4a-bf90-d5483c9571c5",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "9427df23-0f42-4e1e-bf99-a6133d841c4a",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "942bd215-1a66-44be-af65-6a1c0318dbe2",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "98569e20-8f32-4f31-bf34-0e91590ae9d3",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "a63cc0bd-cda4-4178-b705-37dc439d3e0f",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "aaa64d2d-2fa3-45e5-b332-0b031b9b30e8",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "ad1eeff9-20d7-4c82-a04e-903acab0bfc1",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "ae8a10e6-19d6-44a3-a02d-a2bdfc707742",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "b0e86710-7fb7-4a6c-a064-32e9b829509e",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "b318f84a-b872-429b-ac6d-a01b96814452",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "b6faa975-0add-4f35-8d1c-70bba45c4424",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "b73e81f3-6303-48ad-9822-b69fc00c15ef",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "baf19753-7502-405f-8745-370519b20483",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "c99ce9c1-ced7-4c3e-aca0-10e69ce0cb02",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "d367bd60-64ca-4364-98ea-276775bddd94",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "d389df0a-e0d7-4607-833c-75a6fdac2c2d",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "d627d7c6-ded5-481a-8f2e-7e16b1e6faf6",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "ddca0ddc-4e9d-4bbb-92a1-f7c4dd7ef7ce",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "e016b22b-e0eb-436d-8fd7-160c4eaed6e2",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "ed66d4f5-8220-45dc-ab4a-20d1749c74e6",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "ee40564d-486e-4f68-a5ca-7a621edae0fb",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "ee40564d-486e-4f68-a5ca-7a621edae0fb",
      "parameter_name"  = "secondPrivateDnsZoneId"
    },
    {
      "definition_name" = "ef9fe2ce-a588-4edd-829c-6247069dcfdb",
      "parameter_name"  = "dcrResourceId"
    },
    {
      "definition_name" = "f0fcf93c-c063-4071-9668-c47474bd3564",
      "parameter_name"  = "privateDnsZoneId"
    },
    {
      "definition_name" = "f91991d1-5383-4c95-8ee5-5ac423dd8bb1",
      "parameter_name"  = "userAssignedIdentityResourceId"
    },
    {
      "definition_name" = "fbc14a67-53e4-4932-abcc-2049c6706009",
      "parameter_name"  = "privateDnsZoneId"
    }
  ]
  description = <<DESCRIPTION
This list of objects allows you to set the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.
This allows you to correct policies that haven't been authored correctly and means that the provider can generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to set the assignPermissions property for.

The default value has been populated with the Azure Landing Zones policies that are assigned by default, but do not have the correct parameter metadata.
DESCRIPTION
}

variable "override_policy_definition_parameter_assign_permissions_unset" {
  type = set(object({
    definition_name = string
    parameter_name  = string
  }))
  default     = null
  description = <<DESCRIPTION
This list of objects allows you to unset the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.
This allows you to correct policies that haven't been authored correctly, or prevent permissions being assigned for policies that are disabled in a policy set. The provider can then generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to unset the assignPermissions property for.
DESCRIPTION
}

variable "parent_id_overrides" {
  type = object({
    policy_assignments     = optional(map(string), {})
    policy_definitions     = optional(map(string), {})
    policy_set_definitions = optional(map(string), {})
    role_definitions       = optional(map(string), {})
  })
  default     = {}
  description = <<DESCRIPTION
A map of parent_id overrides for resources that have inconsistent casing in Azure.
This allows you to override the parent_id path for specific resources to avoid forced replacement due to casing differences.

The object has the following optional attributes:

- `policy_assignments` - (Optional) A map of policy assignment keys to parent_id path overrides. The key should be in the format `management_group_id/assignment_name`. The value should be the parent_id path prefix (e.g., `/providers/Microsoft.Management/managementgroups` instead of `/providers/Microsoft.Management/managementGroups`).
- `policy_definitions` - (Optional) A map of policy definition keys to parent_id path overrides. The key should be in the format `management_group_id/definition_name`. The value should be the parent_id path prefix.
- `policy_set_definitions` - (Optional) A map of policy set definition keys to parent_id path overrides. The key should be in the format `management_group_id/set_definition_name`. The value should be the parent_id path prefix.
- `role_definitions` - (Optional) A map of role definition keys to parent_id path overrides. The key should be in the format `management_group_id/role_definition_name`. The value should be the parent_id path prefix.

Example:

```hcl
module "alz" {
  source = "Azure/terraform-azurerm-avm-ptn-alz/azurerm"
  
  # the key format is `management group id/policy assignment name`
  parent_id_overrides = {
    policy_definitions = {
      "alz/Deny-Classic-Resources" = "/providers/Microsoft.Management/managementgroups"
    }
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "partner_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
A value to be included in the telemetry tag. Requires the `enable_telemetry` variable to be set to `true`. The must be in the following format:

`<PARTNER_ID_UUID>:<PARTNER_DATA_UUID>`

e.g.

`00000000-0000-0000-0000-000000000000:00000000-0000-0000-0000-000000000000`
DESCRIPTION

  validation {
    error_message = "The partner id must be in the format <PARTNER_ID_UUID>:<PARTNER_DATA_UUID>. All letters must be lowercase"
    condition     = var.partner_id == null ? true : can(regex("^[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}:[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}$", var.partner_id))
  }
}

variable "policy_assignment_non_compliance_message_settings" {
  type = object({
    fallback_message_enabled = optional(bool, true)
    fallback_message         = optional(string, "This resource {enforcementMode} be compliant with the assigned policy.")
    fallback_message_unsupported_assignments = optional(list(string), [
      "Deny-Privileged-AKS",
      "Enforce-AKS-HTTPS",
      "Deny-Priv-Esc-AKS"
    ])
    enforcement_mode_placeholder = optional(string, "{enforcementMode}")
    enforced_replacement         = optional(string, "must")
    not_enforced_replacement     = optional(string, "should")
  })
  default     = {}
  description = <<DESCRIPTION
Settings for the non-compliance messages of policy assignments. This is used to ensure that the non-compliance messages are set correctly for policy assignments that do not have them set.
  The object has the following optional attributes:
- `fallback_message_enabled` - (Optional) Whether to enable the fallback message for policy assignments that do not have a non-compliance message set. Defaults to `true`.
- `fallback_message` - (Optional) The fallback message to use for policy assignments that do not have a non-compliance message set. Defaults to "This resource {enforcementMode} be compliant with the assigned policy."
- `fallback_message_unsupported_assignments` - (Optional) A list of policy assignment names that do not support non-compliance messages. Defaults to a list of Azure Landing Zones policy assignments that do not support non-compliance messages.
- `enforcement_mode_placeholder` - (Optional) The placeholder to use for the enforcement mode in the fallback message. Defaults to "{enforcementMode}".
- `enforced_replacement` - (Optional) The replacement string to use for the enforcement mode when the policy assignment is enforced. Defaults to "must".
- `not_enforced_replacement` - (Optional) The replacement string to use for the enforcement mode when the policy assignment is not enforced. Defaults to "should".
DESCRIPTION
  nullable    = false
}

variable "policy_assignments_to_modify" {
  type = map(object({
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
  default     = {}
  description = <<DESCRIPTION
A map of policy assignment objects to modify the ALZ architecture with.
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
DESCRIPTION
}

variable "policy_default_values" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
A map of default values to apply to policy assignments. The key is the default name as defined in the library, and the value is an JSON object containing a single `value` attribute with the values to apply. This to mitigate issues with the Terraform type system. E.g. `{ defaultName = jsonencode({ value = \"value\"}) }`
DESCRIPTION
}

variable "resource_api_versions" {
  type = object({
    policy_assignment     = optional(string, "2024-04-01")
    policy_definition     = optional(string, "2023-04-01")
    policy_set_definition = optional(string, "2023-04-01")
    role_assignment       = optional(string, "2022-04-01")
    role_definition       = optional(string, "2022-04-01")
    management_group      = optional(string, "2023-04-01")
  })
  default     = {}
  description = <<DESCRIPTION
EXPERIMENTAL: Modify this to change the API versions used for each resource type. Added to support clouds with different API versions, e.g. US Government.

Modifying these values may result in unexpected behavior or compatibility issues, which we cannot test for. Please do not raise issues against this module if you change these values.
DESCRIPTION
  nullable    = false
}

variable "retries" {
  type = object({
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
    role_assignments = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
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
        "AuthorizationFailed",    # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "ResourceNotFound",       # If the resource has just been created, retry until it is available.
        "RoleAssignmentNotFound", # If the resource has just been created, retry until it is available.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    hierarchy_settings = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
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
  default     = {}
  description = <<DESCRIPTION
The retry settings to apply to the CRUD operations. Value is a nested object, the top level keys are the resources and the values are an object with the following attributes:

- `error_message_regex` - (Optional) A list of error message regexes to retry on. Defaults to `null`, which will will disable retries. Specify a value to enable.
- `interval_seconds` - (Optional) The initial interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `max_interval_seconds` - (Optional) The maximum interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `multiplier` - (Optional) DEPRECATED The multiplier to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value. This value is deprecated and will be removed in a future version.
- `randomization_factor` - DEPRECATED (Optional) The randomization factor to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value. This value is deprecated and will be removed in a future version.

For more information please see the provider documentation here: <https://registry.terraform.io/providers/Azure/azapi/azurerm/latest/docs/resources/resource#nestedatt--retry>
DESCRIPTION
}

variable "schema_validation_enabled" {
  type = object({
    hierarchy_settings     = optional(bool, true)
    management_groups      = optional(bool, true)
    policy_assignments     = optional(bool, true)
    policy_definitions     = optional(bool, true)
    policy_set_definitions = optional(bool, true)
    role_assignments       = optional(bool, true)
    role_definitions       = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
Enable or disable schema validation for each resource type. Defaults to `true` for all resource types.
If you encounter issues with schema validation, please raise an issue against the AzAPI provider.
DESCRIPTION
}

variable "subscription_placement" {
  type = map(object({
    subscription_id       = string
    management_group_name = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of subscriptions to place into management groups. The key is deliberately arbitrary to avoid issues with known after apply values. The value is an object:

- `subscription_id` - (Required) The id of the subscription to place in the management group.
- `management_group_name` - (Required) The name of the management group to place the subscription in.
DESCRIPTION
  nullable    = false

  validation {
    error_message = "All subscription ids must be valid UUIDs."
    condition     = alltrue([for v in var.subscription_placement : can(regex("^[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}$", v.subscription_id))])
  }
}

variable "timeouts" {
  type = object({
    management_group = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
    role_definition = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
    role_assignment = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
    policy_definition = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
    policy_set_definition = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
    policy_assignment = optional(object({
      create = optional(string, "20m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_role_assignment = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "60m")
      }), {}
    )
  })
  default     = {}
  description = <<DESCRIPTION
A map of timeouts to apply to the creation and destruction of resources.
If using retry, the maximum elapsed retry time is governed by this value.

The object has attributes for each resource type, with the following optional attributes:

- `create` - (Optional) The timeout for creating the resource. Defaults to `15m` apart from policy assignments, where this is set to `20m`.
- `delete` - (Optional) The timeout for deleting the resource. Defaults to `5m`.
- `update` - (Optional) The timeout for updating the resource. Defaults to `5m`.
- `read` - (Optional) The timeout for reading the resource. Defaults to `5m`.

Each time duration is parsed using this function: <https://pkg.go.dev/time#ParseDuration>.
DESCRIPTION
}
