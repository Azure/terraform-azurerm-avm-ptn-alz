# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "landing_zones" {
  base_archetype = "landing_zones"
  name           = "landing-zones"
  display_name   = "landing zones"
  parent_id      = data.alzlib_archetype.root.name
}

# create landing-zones management group and policy/roles
module "archetype_landing_zones" {
  source    = "./modules/archetype"
  archetype = data.alzlib_archetype.root
}
