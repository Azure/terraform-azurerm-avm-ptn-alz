variable "delays" {
  type = object({
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
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
DEPRECATED: Please use the new `retries` variable instead to allow the provider to retry on certain errors.

A map of delays to apply to the creation and destruction of resources.
Included to work around some race conditions in Azure.
DESCRIPTION
}
