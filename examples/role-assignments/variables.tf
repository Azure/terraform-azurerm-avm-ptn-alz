variable "prefix" {
  type        = string
  default     = ""
  description = "Management group prefix"
  nullable    = false
}

variable "principal_type" {
  type        = string
  default     = "ServicePrincipal"
  description = "The principal type to use for the role assignment."
  nullable    = false
}
