variable "name" {
  type        = string
  nullable    = false
  description = "The name of the policy assignment."
}

variable "properties" {
  type        = any
  nullable    = false
  description = "The body properties object of the policy assignment."
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The parent ID of the policy assignment."
}

variable "location" {
  type        = string
  description = "Value of the location field in the resource."
  default     = null
}

variable "response_export_values" {
  type        = set(string)
  description = "List of values to export from the response."
  default     = null
}

variable "replace_triggered_by" {
  type        = any
  description = "Values that trigger a replacement."
  default     = null
}

variable "type" {
  type        = string
  description = "The type of the resource."
}
