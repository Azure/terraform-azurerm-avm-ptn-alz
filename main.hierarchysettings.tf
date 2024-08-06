data "azapi_client_config" "hierarchysettings" {}

resource "azapi_resource" "hierarchysettings" {
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
}

resource "azapi_update_resource" "hierarchysettings" {
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
}
