locals {
  policy_assignment_new_assignment = {
    # required properties
    display_name           = "new assignment"
    policy_definition_name = "my-definition"

    # optional properties
    description      = "description"
    enforcement_mode = "Default"
    overrides = [
      {
        kind = "policyEffect"
        selector = {
          kind   = "resourceLocation"
          not_in = ["northeurope"]
        }
        value = "Disabled"
      }
    ]
    parameters = {
      my-parameter = "my value"
    }
    resource_selectors = {
      name = {
        in     = ["westeurope"]
        kind   = "resourceLocation"
      }
    }
  }
}
