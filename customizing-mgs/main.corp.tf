# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "corp" {
  base_archetype = "corp" # This is the built-in archetype that is baked into the provider.
                          # We can use "empty" to create a completely custom archetype.
  name           = "corp"
  display_name   = "corp"
  parent_id      = data.alz_archetype.landing_zones.landing_zones

  # customization starts here

  # This is a map of new assignments to create, this works similarly to the current module
  # We do not read from JSON and instead declare the required inputs here so that we can use
  # the Terraform resource graph.
  # If we use JSON files then we either have to augment the JSON using `template_file()`,
  # which is inefficient, or use additional data source inputs to augment the data.
  # Using additional inputs means there is more than one way to achieve the same thing,
  # we have had feedback that this is confusing in the current module and are moving away from this approach.
  policy_assignments_to_add = local.policy_assignments_to_add_corp
  # Note: The above can also override existing assignments with the same name.

  # these refer to the assignment name (id) that is defined in the archetype from the provider
  policy_assignments_to_remove = [
    "my-unwanted-assignment",
    "my-other-unwanted-assignment"
  ]

  policy_definitions_to_add = [
    "my-new-definition"
  ]

  policy_set_definitions_to_add = [
    "my-new-set-definition"
  ]

  # these refer to the definition name (id) that is defined in the archetype from the provider
  policy_definitions_to_remove = [
    "my-unwanted-definition",
    "my-other-unwanted-definition"
  ]
}

# create landing-zones management group and policy/roles
# This is unchanged as the provider has done all the hard work on the data processing
module "archetype_corp" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.corp
}
