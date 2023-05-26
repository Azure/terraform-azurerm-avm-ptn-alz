# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "sandbox" {
  base_archetype = "sandbox"
  name           = "sandbox"
  display_name   = "sandbox"
  parent_id      = data.alz_archetype.root.name
}

# create landing-zones management group and policy/roles
module "archetype_sandbox" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.sandbox
}
