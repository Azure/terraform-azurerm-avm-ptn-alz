# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "corp" {
  base_archetype = "corp"
  name           = "corp"
  display_name   = "corp"
  parent_id      = data.alzlib_archetype.landing_zones.name
}

# create landing-zones management group and policy/roles
module "archetype_corp" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alzlib_archetype.corp
}
