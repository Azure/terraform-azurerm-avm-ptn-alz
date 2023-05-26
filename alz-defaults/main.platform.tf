# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "platform" {
  base_archetype = "platform"
  name           = "platform"
  display_name   = "platform"
  parent_id      = data.alz_archetype.root.name
}

# create landing-zones management group and policy/roles
module "archetype_platform" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.platform
}
