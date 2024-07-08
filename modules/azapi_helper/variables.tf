variable "body" {
  type        = any
  description = "The body object of the resource."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of resource."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The parent ID of the resource."
  nullable    = false
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

variable "location" {
  type        = string
  default     = null
  description = "Location of the resource."
}

variable "replace_triggered_by" {
  type        = any
  default     = null
  description = "Values that trigger a replacement."
}

variable "response_export_values" {
  type        = set(string)
  default     = null
  description = "List of values to export from the response, made available in the output."
}

variable "timeouts" {
  type = object({
    create = string
    delete = string
    update = string
    read   = string
  })
  default = {
    create = "10m"
    delete = "10m"
    update = "10m"
    read   = "10m"
  }
  description = <<DESCRIPTION
  A map of timeouts to apply to the creation and destruction of the resource.
  DESCRIPTION
}
