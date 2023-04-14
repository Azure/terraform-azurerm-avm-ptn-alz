# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "connectivity" {
  base_archetype = "connectivity"
  name           = "connectivity"
  display_name   = "connectivity"
  parent_id      = data.alzlib_archetype.platform.name
}

# create landing-zones management group and policy/roles
module "archetype_connectivity" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alzlib_archetype.connectivity
}
