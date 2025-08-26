variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable telemetry for the module."
  nullable    = false
}

variable "prefix" {
  type        = string
  default     = ""
  description = "Management group prefix"
  nullable    = false
}
