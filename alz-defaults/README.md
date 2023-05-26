# alz-defaults

This is an exmaple of how the default ALZ architecture could look.

There is a `main.tf` file that sets up the alz provider and uses a data source for the tenant id (used to identity the tenant root management group).

For each MG to deploy, there is a `.tf ` file, this is to aid readability, the content can be in one big file if preferred.

In each `.tf` file, there is:

- a data source used to query the alz provider for the requried information to deploy the management group.
- a module declaration which takes the outputs of the provider and deploys the resources using the standard Azure providers.

Example:

```terraform
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
  archetype = data.alzlib_archetype.root
}
```
