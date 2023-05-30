locals {
  policy_assignment_new_other_assignment = {
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
