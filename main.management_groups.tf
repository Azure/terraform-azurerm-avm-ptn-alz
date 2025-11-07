resource "azapi_resource" "management_groups_level_0" {
  for_each = local.management_groups_level_0

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  response_export_values = []
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }
}

resource "azapi_resource" "management_groups_level_1" {
  for_each = local.management_groups_level_1

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_0]
}

resource "azapi_resource" "management_groups_level_2" {
  for_each = local.management_groups_level_2

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_1]
}

resource "azapi_resource" "management_groups_level_3" {
  for_each = local.management_groups_level_3

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_2]
}

resource "azapi_resource" "management_groups_level_4" {
  for_each = local.management_groups_level_4

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_3]
}

resource "azapi_resource" "management_groups_level_5" {
  for_each = local.management_groups_level_5

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_4]
}

resource "azapi_resource" "management_groups_level_6" {
  for_each = local.management_groups_level_6

  name      = each.value.id
  parent_id = "/"
  type      = "Microsoft.Management/managementGroups@${var.resource_api_versions.management_group}"
  body = {
    properties = {
      details = {
        parent = {
          id = "${coalesce(lookup(var.parent_id_overrides.management_groups, each.value.id, null), "/providers/Microsoft.Management/managementGroups")}/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = var.retries.management_groups.error_message_regex != null ? {
    error_message_regex  = var.retries.management_groups.error_message_regex
    interval_seconds     = lookup(var.retries.management_groups, "interval_seconds", null)
    max_interval_seconds = lookup(var.retries.management_groups, "max_interval_seconds", null)
    multiplier           = lookup(var.retries.management_groups, "multiplier", null)
    randomization_factor = lookup(var.retries.management_groups, "randomization_factor", null)
  } : null
  schema_validation_enabled = var.schema_validation_enabled.management_groups
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_5]
}
