mock_provider "alz" {}
mock_provider "azapi" {}
mock_provider "modtm" {}

variables {
  management_group_hierarchy_settings = {
    default_management_group_name            = "test"
    require_authorization_for_group_creation = true
    update_existing                          = false
  }
  parent_resource_id = "test"
  location           = "test"
  architecture_name  = "test"
}

run "default" {
  command = plan

  variables {
    management_group_hierarchy_settings = null
  }

  assert {
    condition     = length(azapi_resource.hierarchy_settings) == 0
    error_message = "The hierarchy settings resource should not be created."
  }

  assert {
    condition     = length(azapi_update_resource.hierarchy_settings) == 0
    error_message = "The hierarchy settings update resource should not be created."
  }
}

run "creation" {
  command = plan

  assert {
    condition     = length(azapi_resource.hierarchy_settings) == 1
    error_message = "The hierarchy settings resource should be created."
  }

  assert {
    condition     = azapi_resource.hierarchy_settings[0].body.properties.defaultManagementGroup == "test"
    error_message = "The default management group is not correct."
  }

  assert {
    condition     = length(azapi_update_resource.hierarchy_settings) == 0
    error_message = "The hierarchy settings update resource should not be created."
  }
}

run "update" {
  command = plan

  variables {
    management_group_hierarchy_settings = {
      default_management_group_name            = "test"
      require_authorization_for_group_creation = true
      update_existing                          = true
    }
  }

  assert {
    condition     = length(azapi_resource.hierarchy_settings) == 0
    error_message = "The hierarchy settings resource should not be created."
  }

  assert {
    condition     = azapi_update_resource.hierarchy_settings[0].body.properties.defaultManagementGroup == "test"
    error_message = "The default management group is not correct."
  }

  assert {
    condition     = length(azapi_update_resource.hierarchy_settings) == 1
    error_message = "The hierarchy settings update resource should be created."
  }
}
