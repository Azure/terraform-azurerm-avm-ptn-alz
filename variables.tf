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
The resource id of the parent management group. Use the tenant id to create a child of the tenant root group.
The `azurerm_client_config`/`azapi_client_config` data sources are able to retrieve the tenant id.
DESCRIPTION
}

variable "delays" {
  type = object({
    after_management_group = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }), {})
    after_policy_definitions = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }), {})
    after_policy_set_definitions = optional(object({
      create  = optional(string, "30s")
      destroy = optional(string, "0s")
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
A map of delays to apply to the creation and destruction of resources.
Included to work around some race conditions in Azure.
DESCRIPTION
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

variable "timeouts" {
  type = object({
    management_group = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
    role_definition = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
    policy_definition = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
    policy_set_definition = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
    policy_assignment = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
    policy_role_assignment = optional(object({
      create = optional(string, "10m")
      delete = optional(string, "10m")
      update = optional(string, "10m")
      read   = optional(string, "10m")
      }), {}
    )
  })
  default     = {}
  description = <<DESCRIPTION
A map of timeouts to apply to the creation and destruction of resources.
DESCRIPTION
}
