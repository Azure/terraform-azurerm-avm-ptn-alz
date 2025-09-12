data "azapi_client_config" "hierarchy_settings" {}

resource "azapi_resource" "hierarchy_settings" {
  count = var.management_group_hierarchy_settings != null && !try(var.management_group_hierarchy_settings.update_existing, true) ? 1 : 0

  name      = "default"
  parent_id = local.tenant_root_group_resource_id
  type      = "Microsoft.Management/managementGroups/settings@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      defaultManagementGroup               = provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [var.management_group_hierarchy_settings.default_management_group_name])
      requireAuthorizationForGroupCreation = var.management_group_hierarchy_settings.require_authorization_for_group_creation
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = var.retries.hierarchy_settings.error_message_regex != null ? {
    error_message_regex  = var.retries.hierarchy_settings.error_message_regex
    interval_seconds     = lookup(var.retries.hierarchy_settings, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.hierarchy_settings, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.hierarchy_settings, "multiplier", null)
    randomization_factor = lookup(var.retries.hierarchy_settings, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.hierarchy_settings
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_update_resource" "hierarchy_settings" {
  count = var.management_group_hierarchy_settings != null && try(var.management_group_hierarchy_settings.update_existing, false) ? 1 : 0

  name      = "default"
  parent_id = local.tenant_root_group_resource_id
  type      = "Microsoft.Management/managementGroups/settings@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      defaultManagementGroup               = provider::azapi::tenant_resource_id("Microsoft.Management/managementGroups", [var.management_group_hierarchy_settings.default_management_group_name])
      requireAuthorizationForGroupCreation = var.management_group_hierarchy_settings.require_authorization_for_group_creation
    }
  }
  read_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = var.retries.hierarchy_settings.error_message_regex != null ? {
    error_message_regex  = var.retries.hierarchy_settings.error_message_regex
    interval_seconds     = lookup(var.retries.hierarchy_settings, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.hierarchy_settings, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.hierarchy_settings, "multiplier", null)
    randomization_factor = lookup(var.retries.hierarchy_settings, "randomization_factor", null)
  } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
