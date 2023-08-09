<!-- BEGIN_TF_DOCS -->
# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.
It uses the ALZ management module to deploy the Log Analytics workspace and Automation Account.

See the [GitHub repo](https://github.com/Azure/terraform-azurerm-alz/blob/main/examples/alzreference/main.tf) for more information.

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.68.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Modules

The following Modules are called:

### <a name="module_alz_landing_zones"></a> [alz\_landing\_zones](#module\_alz\_landing\_zones)

Source: ../../

Version:

### <a name="module_alz_management"></a> [alz\_management](#module\_alz\_management)

Source: Azure/alz-management/azurerm

Version: 0.1.4

### <a name="module_alz_root"></a> [alz\_root](#module\_alz\_root)

Source: ../../

Version:

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Resources

The following resources are used by this module:

- [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Outputs

No outputs.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
<!-- END_TF_DOCS -->