# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "management" {
  base_archetype = "management"
  name           = "management"
  display_name   = "management"
  parent_id      = data.alz_archetype.platform.name
}

# create landing-zones management group and policy/roles
module "archetype_management" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.management
}
