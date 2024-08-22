resource "azapi_resource" "management_groups_level_0" {
  for_each = local.management_groups_level_0

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }
}

resource "azapi_resource" "management_groups_level_1" {
  for_each = local.management_groups_level_1

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

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

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

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

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

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

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

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

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

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

  type = "Microsoft.Management/managementGroups@2023-04-01"
  body = {
    properties = {
      details = {
        parent = {
          id = "/providers/Microsoft.Management/managementGroups/${each.value.parent_id}"
        }
      }
      displayName = each.value.display_name
    }
  }
  name      = each.value.id
  parent_id = "/"
  replace_triggers_external_values = [
    each.value.parent_id,
  ]
  retry = length(var.retry.management_groups.error_message_regex) > 0 ? {
    error_message_regex  = var.retry.management_groups.error_message_regex
    interval_seconds     = var.retry.management_groups.interval_seconds
    max_interval_seconds = var.retry.management_groups.max_interval_seconds
    multiplier           = var.retry.management_groups.multiplier
    randomization_factor = var.retry.management_groups.randomization_factor
  } : null

  timeouts {
    create = var.timeouts.management_group.create
    delete = var.timeouts.management_group.delete
    read   = var.timeouts.management_group.read
    update = var.timeouts.management_group.update
  }

  depends_on = [azapi_resource.management_groups_level_5]
}
