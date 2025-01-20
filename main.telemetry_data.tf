data "alz_metadata" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}
