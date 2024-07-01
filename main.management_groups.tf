module "management_groups_level_0" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_0
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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

  replace_triggered_by = []
}
module "management_groups_level_1" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_1
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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

  depends_on = [module.management_groups_level_0]
}

module "management_groups_level_2" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_2
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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
  replace_triggered_by = [
    each.value.parent_id,
    each.value.id,
  ]
  depends_on = [module.management_groups_level_1]
}

module "management_groups_level_3" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_3
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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

  depends_on = [module.management_groups_level_2]
}

module "management_groups_level_4" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_4
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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

  depends_on = [module.management_groups_level_3]
}

module "management_groups_level_5" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_5
  name      = each.value.id
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
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

  depends_on = [module.management_groups_level_4]
}

module "management_groups_level_6" {
  source    = "./modules/azapi_helper"
  for_each  = local.management_groups_level_6
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  name      = each.value.id
  parent_id = "/"
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

  depends_on = [module.management_groups_level_5]
}
