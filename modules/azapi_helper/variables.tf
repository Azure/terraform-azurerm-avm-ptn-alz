variable "name" {
  type        = string
  nullable    = false
  description = "The name of resource."
}

variable "body" {
  type        = any
  nullable    = false
  description = "The body object of the resource."
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The parent ID of the resource."
}

variable "location" {
  type        = string
  description = "Location of the resource."
  default     = null
}

variable "response_export_values" {
  type        = set(string)
  description = "List of values to export from the response, made available in the output."
  default     = null
}

variable "replace_triggered_by" {
  type        = any
  description = "Values that trigger a replacement."
  default     = null
}

variable "type" {
  type        = string
  description = "The type and API version of the resource."
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `type` - Either: `SystemAssigned`, `SystemAssigned, UserAssigned`, or `UserAssigned`.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION

  validation {
    error_message = "If `identity` is specified, `type` must be specified."
    condition     = var.identity == null ? true : lookup(var.identity, "type", null) != null
  }

  # validation {
  #   error_message = "If `identity` is specified and `type` contains `UserAssigned`, `identity_ids` must also be specified."
  #   condition     = var.identity == null ? true : contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type) && length(var.identity.identity_ids) > 0
  # }

  validation {
    error_message = "If `identity` is specified, `type` must be one of `SystemAssigned`, `SystemAssigned, UserAssigned`, or `UserAssigned`."
    condition     = var.identity == null ? true : contains(["None", "SystemAssigned", "SystemAssigned, UserAssigned", "UserAssigned"], var.identity.type)
  }
}

variable "ignore_missing_property" {
  type        = bool
  default     = false
  description = "If set to true, the resource will not be replaced if a property is missing."
}
