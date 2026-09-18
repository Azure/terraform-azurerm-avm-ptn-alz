variable "prefix" {
  type     = string
  nullable = false
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = "Enable telemetry for the module."
  nullable    = false
}
