variable "id" {
  type        = string
  description = <<DESCRIPTION
The id of the management group. This must be unique and cannot be changed after creation.
DESCRIPTION
}

variable "display_name" {
  type        = string
  description = <<DESCRIPTION
The display name of the management group.
DESCRIPTION
}

variable "base_archetype" {
  type        = string
  description = <<DESCRIPTION
The archetype of the management group.
This should be one of the built in archetypes, or a custom one defined in one of the `lib_dirs`.
DESCRIPTION
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The id of the parent management group. Use the tenant id to create a child of the tenant root group.
The `azurerm_client_config` data source from the AzureRM provider is useful to get the tenant id.
DESCRIPTION
}

variable "default_location" {
  type        = string
  description = <<DESCRIPTION
The default location for resources in this management group. Used for policy managed identities.
DESCRIPTION
}

variable "default_log_analytics_workspace_id" {
  type        = string
  description = <<DESCRIPTION
The resource id of the default log analytics workspace to use for policy parameters.
DESCRIPTION
  default     = null
}

variable "default_private_dns_zone_resource_group_id" {
  type        = string
  description = <<DESCRIPTION
Resource group id for the private dns zones to use in policy parameters.
DESCRIPTION
  default     = null
}

variable "role_assignments" {
  type = map(object({
    role_definition_id   = optional(string, "")
    role_definition_name = optional(string, "")
    principal_id         = string
    description          = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for _, v in var.role_assignments : alltrue([
        !(length(v.role_definition_id) > 0 && length(v.role_definition_name) > 0),
        !(length(v.role_definition_id) == 0 && length(v.role_definition_name) == 0)
      ])
    ])
    error_message = "Specify one (and only one) of `role_definition_id` and `role_definition_name`."
  }

  validation {
    condition     = length(toset(values(var.role_assignments))) == length(var.role_assignments)
    error_message = "Role assignment values must not be duplicates."
  }
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to associated principals and role definitions to the management group.

The key is the your reference for the role assignment. The value is a map of the properties of the role assignment.

- `role_definition_id` - (Optional) The id of the role definition to assign to the principal. Conflicts with `role_definition_name`. `role_definition_id` and `role_definition_name` are mutually exclusive and one of them must be supplied.
- `role_definition_name` - (Optional) The name of the role definition to assign to the principal. Conflicts with `role_definition_id`.
- `principal_id` - (Required) The id of the principal to assign the role definition to.
- `description` - (Optional) The description of the role assignment.

DESCRIPTION
}

variable "policy_assignments_to_add" {
  type = map(object({
    display_name               = optional(string, null)
    enforcement_mode           = optional(string, null)
    identity                   = optional(string, null)
    identity_ids               = optional(list(string), null)
    policy_definition_id       = optional(string, null)
    policy_definition_name     = optional(string, null)
    policy_set_definition_name = optional(string, null)
    parameters                 = optional(string, null)
    non_compliance_message = optional(set(object({
      message                        = string
      policy_definition_reference_id = optional(string, null)
    })), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of policy assignment objects to add or update the alz archetype with.
When updating a policy assignment, you only need to specify the properties you want to change.

The key is the name of the policy assignment.
The value is a map of the properties of the policy assignment.

- `display_name` - (Optional) The display name of the policy assignment.
- `enforcement_mode` - (Optional) The enforcement mode of the policy assignment. Possible values are `Default` and `DoNotEnforce`.
- `identity` - (Optional) The identity of the policy assignment. Possible values are `SystemAssigned` and `UserAssigned`.
- `identity_ids` - (Optional) A set of ids of the user assigned identities to assign to the policy assignment.
- `non_compliance_message` - (Optional) A set of non compliance message objects to use for the policy assignment. Each object has the following properties:
  - `message` - (Required) The non compliance message.
  - `policy_definition_reference_id` - (Optional) The reference id of the policy definition to use for the non compliance message.
- `parameters` - (Optional) A JSON string of parameters to use for the policy assignment. Use `jsonencode()` to convert a map of the parameter names to values.
- `policy_definition_id` - (Optional) The id of the policy definition to assign to the policy assignment. Conflicts with `policy_definition_name` and `policy_set_definition_name`.
- `policy_definition_name` - (Optional) The name of the policy definition to assign to the policy assignment. Conflicts with `policy_definition_id` and `policy_set_definition_name`.
- `policy_set_definition_name` - (Optional) The name of the policy set definition to assign to the policy assignment. Conflicts with `policy_definition_id` and `policy_definition_name`.
DESCRIPTION
}

variable "policy_assignments_to_remove" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of policy assignment names to remove from the `base_archetype`.
DESCRIPTION
}

variable "policy_definitions_to_add" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of policy definition names to add to the `base_archetype`.
The definition must exist in one of the loaded lib directories.
DESCRIPTION
}

variable "policy_definitions_to_remove" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of policy definition names to remove from the `base_archetype`.
DESCRIPTION
}

variable "policy_set_definitions_to_add" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of policy set definition names to add to the `base_archetype`.
The definition must exist in one of the loaded lib directories.
DESCRIPTION
}

variable "policy_set_definitions_to_remove" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of policy set definition names to remove from the `base_archetype`.
DESCRIPTION
}

variable "role_definitions_to_add" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of role definition names to add to the `base_archetype`.
The definition must exist in one of the loaded lib directories.
DESCRIPTION
}

variable "role_definitions_to_remove" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of role definition names to remove from the `base_archetype`.
DESCRIPTION
}

variable "subscription_ids" {
  type        = set(string)
  default     = []
  description = <<DESCRIPTION
A set of subscription ids to move under this management group.
DESCRIPTION
}

variable "delays" {
  type = object({
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
  default     = {}
  description = <<DESCRIPTION
A map of delays to apply to the creation and destruction of resources.
Included to work around some race conditions in Azure.
DESCRIPTION
}
