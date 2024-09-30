data "azapi_client_config" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

data "alz_metadata" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

data "modtm_module_source" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  module_path = path.module
}

resource "random_uuid" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

resource "modtm_telemetry" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  tags = merge({
    subscription_id        = one(data.azapi_client_config.telemetry).subscription_id
    tenant_id              = one(data.azapi_client_config.telemetry).tenant_id
    module_source          = one(data.modtm_module_source.telemetry).module_source
    module_version         = one(data.modtm_module_source.telemetry).module_version
    random_id              = one(random_uuid.telemetry).result
    alz_library_references = jsonencode(one(data.alz_metadata.telemetry).alz_library_references)
    },
    var.partner_id != null ? { partner_id = var.partner_id } : {}
  )
}
