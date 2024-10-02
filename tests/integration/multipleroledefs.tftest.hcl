provider "alz" {
  library_references = [{
    custom_url = "./tests/integration/testdata/multipleroledefs"
  }]
}

variables {
  location          = "swedencentral"
  architecture_name = "test"
}

run "setup" {
  module {
    source = "./tests/integration/modules/tenant_id"
  }
}

run "first_apply" {
  variables {
    parent_resource_id = run.setup.tenant_id
  }
  command = apply
}

run "second_apply" {
  variables {
    parent_resource_id = run.setup.tenant_id
  }
  command = apply
}
