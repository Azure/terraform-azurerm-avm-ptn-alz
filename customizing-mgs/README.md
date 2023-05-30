# Customizing

This example shows how we might customize a management group.
The input schema may look cumbersome, but we can use locals, etc. to split the contents into multiple files.
See the `main.tf` and associated `locals.policy_assignments_corp.tf` for details.

```terraform
# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "corp" {
  base_archetype = "corp"
  name           = "corp"
  display_name   = "corp"
  parent_id      = data.alz_archetype.landing_zones.name

  # customization starts here

  # This is a map of new assignments to create.
  # We do not read from JSON and instead declare the required inputs here.
  # Reason being that if we use JSON files then we have to augment this to support
  # data that comes from other Terraform resources.
  # This is best done within Terraform, rather than using `template_file()`.
  # Will also override existing assignments with the same name.
  policy_assignments_to_add = {
    new-assignment = {
      # required properties
      display_name                            = "new assignment"
      policy_definition_name                  = "my-definition"

      # optional properties
      description      = "description"
      enforcement_mode = "Default"
      managed_identity = "UserAssigned"
      managed_identity_ids = ["<my identity resource id>"]
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

  # these refer to the assignment name (id) that is defined in the archetype from the provider
  policy_assignments_to_remove = [
    "my-unwanted-assignment",
    "my-other-unwanted-assignment"
  ]

  # these come from the lib directory specified in the provider block
  policy_definitions_to_add = [
    "my-new-definition"
  ]

  # these refer to the definition name (id) that is defined in the archetype from the provider
  policy_definitions_to_remove = [
    "my-unwanted-definition",
    "my-other-unwanted-definition"
  ]

  # these come from the lib directory specified in the provider block
  policy_set_definitions_to_add = [
    "my-new-set-definition"
  ]

  policy_set_definitions_to_remove = [
    "my-unwanted-set-definition"
  ]

  role_assignments_to_add = [
    {
      "definition"   = "Contributor",
      "principal_id" = "00000000-0000-0000-0000-0000000000"
    }
  ]
}

# create landing-zones management group and policy/roles
# This is unchanged as the provider has done all the hard work on the data processing
module "archetype_corp" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.corp
}
```
