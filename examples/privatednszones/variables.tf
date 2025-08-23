variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable telemetry for the module."
  nullable    = false
}

variable "random_suffix" {
  type        = string
  default     = "fgcsnm"
  description = "Change me to something unique"
}
