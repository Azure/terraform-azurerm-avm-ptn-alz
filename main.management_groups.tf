resource "azapi_resource" "mg0" {
  for_each  = local.management_groups_level_0
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
}

resource "azapi_resource" "mg1" {
  for_each  = local.management_groups_level_1
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg0]
}

resource "azapi_resource" "mg2" {
  for_each  = local.management_groups_level_2
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg1]
}

resource "azapi_resource" "mg3" {
  for_each  = local.management_groups_level_3
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg2]
}

resource "azapi_resource" "mg4" {
  for_each  = local.management_groups_level_4
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg3]
}

resource "azapi_resource" "mg5" {
  for_each  = local.management_groups_level_5
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg4]
}

resource "azapi_resource" "mg6" {
  for_each  = local.management_groups_level_6
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = each.value.id
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
  depends_on = [azapi_resource.mg5]
}
