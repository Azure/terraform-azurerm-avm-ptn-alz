# Using a separate file to allow use of _override file for main telemetry,
# this way it isn't overwritten by repo governance.

data "alz_metadata" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}
