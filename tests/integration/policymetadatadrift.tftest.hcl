# Regression test for Azure/Azure-Landing-Zones#4274.
# Verifies Azure-managed metadata fields (createdBy, createdOn, updatedBy, updatedOn)
# do not cause drift on policy definitions and policy set definitions after deployment.

provider "alz" {
  library_references = [
    {
      custom_url = "tests/integration/testdata/policymetadatadrift"
    }
  ]
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

  assert {
    condition     = length(azapi_resource.policy_definitions) == 1
    error_message = "Expected exactly one test policy definition to be deployed."
  }

  assert {
    condition     = length(azapi_resource.policy_set_definitions) == 1
    error_message = "Expected exactly one test policy set definition to be deployed."
  }
}

run "verify_no_drift" {
  variables {
    parent_resource_id = run.setup.tenant_id
  }

  command = plan

  # If Terraform plans an in-place update, the AzAPI computed `output`
  # attribute becomes unknown (known after apply), and this assertion fails.
  assert {
    condition = alltrue([
      for pd in values(azapi_resource.policy_definitions) : pd.output == {}
    ])
    error_message = "Policy definitions have planned changes after apply. Azure-managed metadata drift was not suppressed."
  }

  assert {
    condition = alltrue([
      for psd in values(azapi_resource.policy_set_definitions) : psd.output == {}
    ])
    error_message = "Policy set definitions have planned changes after apply. Azure-managed metadata drift was not suppressed."
  }
}