resource "random_id" "telem" {
  count = var.enable_telemetry ? 1 : 0

  byte_length = 4
}

# This is the module telemetry deployment that is only created if telemetry is enabled.
# It is deployed to the management group.
resource "azurerm_management_group_template_deployment" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  location            = var.default_location
  management_group_id = azurerm_management_group.this.id
  name                = local.telem_arm_deployment_name
  tags                = null
  template_content    = local.telem_arm_template_content
}
