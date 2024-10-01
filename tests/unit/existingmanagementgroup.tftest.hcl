mock_provider "azapi" {}
mock_provider "modtm" {}

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
