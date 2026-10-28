mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

provider "alz" {
  library_references = [
    {
      custom_url = "./tests/unit/testdata/existingmg"
    }
  ]
}

variables {
  architecture_name  = "existingmg"
  location           = "sweedencentral"
  parent_resource_id = "parent"
}

run "existingmg" {
  command = plan

  assert {
    condition     = data.alz_architecture.this.management_groups[0].exists
    error_message = "The management group level 0 resource should not be created."
  }
}
