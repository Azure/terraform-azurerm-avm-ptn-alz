variable "prefix" {
  type        = string
  description = "The prefix to use for all management group names and display names."
  nullable    = false

  validation {
    error_message = "Length must be between 1 and 40 characters."
    condition     = length(var.prefix) > 0 && length(var.prefix) <= 40
  }

  validation {
    error_message = "Prefix must be alphanumerics, underscores, periods, and hyphens. Must start with alphanumeric."
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.()]*$", var.prefix))
  }
}
