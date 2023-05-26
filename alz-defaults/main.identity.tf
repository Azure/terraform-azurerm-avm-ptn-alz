# Declare landing zones archetype, based on built-in landing-zones definition baked into provider
# but adding additional policy assignments
data "alz_archetype" "identity" {
  base_archetype = "identity"
  name           = "identity"
  display_name   = "identity"
  parent_id      = data.alz_archetype.platform.name
}

# create landing-zones management group and policy/roles
module "archetype_identity" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.identity
}
