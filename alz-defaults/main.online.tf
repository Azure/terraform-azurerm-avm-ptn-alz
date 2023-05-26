# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "online" {
  base_archetype = "online"
  name           = "online"
  display_name   = "online"
  parent_id      = data.alz_archetype.landing_zones.name
}

# create landing-zones management group and policy/roles
module "archetype_online" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.online
}
