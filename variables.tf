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
  type        = map(object({}))
  default     = {}
  description = <<DESCRIPTION
Not implemented yet.
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

variable "policy_non_compliance_message_default" {
  type        = string
  description = <<DESCRIPTION
If set overrides the default non-compliance message used for policy assignments."
DESCRIPTION
  default     = "This resource {enforcementMode} be compliant with the assigned policy."
  validation {
    condition     = var.policy_non_compliance_message_default != null && length(var.policy_non_compliance_message_default) > 0
    error_message = "The policy_non_compliance_message_default value must not be null or empty."
  }
}

variable "policy_non_compliance_message_enforcement_placeholder" {
  type        = string
  description = <<DESCRIPTION
If set overrides the non-compliance message placeholder used in message templates.
DESCRIPTION
  default     = "{enforcementMode}"
  validation {
    condition     = var.policy_non_compliance_message_enforcement_placeholder != null && length(var.policy_non_compliance_message_enforcement_placeholder) > 0
    error_message = "The policy_non_compliance_message_enforcement_placeholder value must not be null or empty."
  }
}

variable "policy_non_compliance_message_enforced_replacement" {
  type        = string
  description = <<DESCRIPTION
If set overrides the non-compliance replacement used for enforced policy assignments.
DESCRIPTION
  default     = "must"
  validation {
    condition     = var.policy_non_compliance_message_enforced_replacement != null && length(var.policy_non_compliance_message_enforced_replacement) > 0
    error_message = "The policy_non_compliance_message_enforced_replacement value must not be null or empty."
  }
}

variable "policy_non_compliance_message_not_enforced_replacement" {
  type        = string
  description = <<DESCRIPTION
If set overrides the non-compliance replacement used for unenforced policy assignments.
DESCRIPTION
  default     = "should"
  validation {
    condition     = var.policy_non_compliance_message_not_enforced_replacement != null && length(var.policy_non_compliance_message_not_enforced_replacement) > 0
    error_message = "The policy_non_compliance_message_not_enforced_replacement value must not be null or empty."
  }
}
