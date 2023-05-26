# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "corp" {
  base_archetype = "corp"
  name           = "corp"
  display_name   = "corp"
  parent_id      = data.alzlib_archetype.landing_zones.name

  # customization starts here

  # This is a map of new assignments to create, this works similarly to the current module
  # We do not read from JSON and instead declare the required inputs here.
  # Reason being that if we use JSON files then we have to augment the data to support things like user assigned managed identity.
  # This is best done withing Terraform, rather than using `template_file()`.
  # Will also override existing assignments with the same name.
  policy_assignments_to_add = local.policy_assignments_to_add_corp

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
  archetype = data.alzlib_archetype.corp
}
