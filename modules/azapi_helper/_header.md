[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Azure/terraform-azurerm-avm-ptn-alz/badge)](https://scorecard.dev/viewer/?uri=github.com/Azure/terraform-azurerm-avm-ptn-alz)

# ALZ Terraform Module (azapi_helper)

> ⚠️ **_Warning_** ⚠️ This module is still in development but is ready for initial testing and feedback via [GitHub Issues](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/issues).

This module is a wrapper for `azapi_resource`, adding convenience features.
As we are using AzAPI, we do not have the full Terraform schema options available for detecting attribute changes that require recreating the resource.

This submodule is therefore used to enable the `terraform_data` method for `replace_triggered_by`: <https://developer.hashicorp.com/terraform/language/resources/terraform-data#example-usage-data-for-replace_triggered_by>.
This allows us to replace the resource when certain key attributes change.

You can use the `var.replace_triggered_by` attribute to specify any data, that when changed, will trigger a replacement of the resource.
