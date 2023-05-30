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
          in     = [""]
          kind   = "resourceLocation"
          not_in = [""]
        }
        value = "Disabled"
      }
    ]
    parameters = {
      my-parameter = "my value"
    }
    resource_selectors = {
      name = {
        in     = [""]
        kind   = "resourceLocation"
        not_in = [""]
      }
    }
  }
}
