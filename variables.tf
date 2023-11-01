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
DESCRIPTION
  default     = null
}

variable "default_private_dns_zone_resource_group_id" {
  type        = string
  description = <<DESCRIPTION
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
DESCRIPTION
}

variable "policy_assignments_to_add" {
  type        = map(object({
    display_name               = optional(string, null)
    enforcement_mode           = optional(string, null)
    identity                   = optional(string, null)
    identity_ids               = optional(list(string), null)
    policy_definition_id       = optional(string, null)
    policy_definition_name     = optional(string, null)
    policy_set_definition_name = optional(string, null)
    parameters                 = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of policy assignment objects to add or update the alz archetype with.
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
