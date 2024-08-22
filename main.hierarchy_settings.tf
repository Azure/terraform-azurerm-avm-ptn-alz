data "azapi_client_config" "hierarchy_settings" {}

resource "azapi_resource" "hierarchy_settings" {
  count = var.management_group_hierarchy_settings != null && !try(var.management_group_hierarchy_settings.update_existing, true) ? 1 : 0

  type = "Microsoft.Management/managementGroups/settings@2023-04-01"
  body = {
    properties = {
      defaultManagementGroup               = "${local.management_group_resource_provider_prefix}${var.management_group_hierarchy_settings.default_management_group_name}"
      requireAuthorizationForGroupCreation = var.management_group_hierarchy_settings.require_authorization_for_group_creation
    }
  }
  name      = "default"
  parent_id = local.tenant_root_group_resource_id
  retry = length(var.retry.hierarchy_settings.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.hierarchy_settings.error_message_regex
    interval_seconds     = var.retry.hierarchy_settings.interval_seconds
    max_interval_seconds = var.retry.hierarchy_settings.max_interval_seconds
    multiplier           = var.retry.hierarchy_settings.multiplier
    randomization_factor = var.retry.hierarchy_settings.randomization_factor
  } : null
}

resource "azapi_update_resource" "hierarchy_settings" {
  count = var.management_group_hierarchy_settings != null && try(var.management_group_hierarchy_settings.update_existing, false) ? 1 : 0

  type = "Microsoft.Management/managementGroups/settings@2023-04-01"
  body = {
    properties = {
      defaultManagementGroup               = "${local.management_group_resource_provider_prefix}${var.management_group_hierarchy_settings.default_management_group_name}"
      requireAuthorizationForGroupCreation = var.management_group_hierarchy_settings.require_authorization_for_group_creation
    }
  }
  name      = "default"
  parent_id = local.tenant_root_group_resource_id
  retry = length(var.retry.hierarchy_settings.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.hierarchy_settings.error_message_regex
    interval_seconds     = var.retry.hierarchy_settings.interval_seconds
    max_interval_seconds = var.retry.hierarchy_settings.max_interval_seconds
    multiplier           = var.retry.hierarchy_settings.multiplier
    randomization_factor = var.retry.hierarchy_settings.randomization_factor
  } : null
}
