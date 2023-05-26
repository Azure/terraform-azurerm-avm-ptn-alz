locals {
  policy_assignments_to_add_corp = {
    # new-assignment
    new-assignment = {
      # required properties
      display_name                            = "new assignment"
      policy_definition_name                  = "my-definition"
      policy_definition_management_group_name = "root" # only required in case of duplicate names

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

    # new-other-assignment - showing simpler example without optional features
    new-other-assignment = {
      # required properties
      display_name                            = "new other assignment"
      policy_definition_name                  = "my-definition2"

      # optional properties
      description      = "description"
      parameters = {
        my-parameter = "my value"
      }
    }
  }

}
