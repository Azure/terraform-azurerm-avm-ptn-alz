# Declare root archetype, based on built-in root definition baked into provider
data "alz_archetype" "root" {
  base_archetype = "root"
  name           = "alz-root"
  display_name   = "ALZ root"
  parent_id      = data.azurerm_client_config.current.tenant_id
}

# create root management group and policy/roles
module "archetype_root" {
  source    = "Azure/alz/azurerm"
  version   = "1.0.0"
  archetype = data.alz_archetype.root
}
