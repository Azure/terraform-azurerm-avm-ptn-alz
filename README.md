# terraform-azurerm-alz

At the moment this repo demonstrates potential v.next configurations for the ALZ Terraform module.
We have adopted a more modular approach and we hope we have addressed key asks, such as the ability to fully customise the management group hierarchy.

The ALZ module proposal is focussed on management groups and policies, with separate modules being created for networking and management.

The new proposed architecture contains two items:

1. A new *provider* to perform the necessary data processing for policies, role assignments and management groups.
2. A new lightweight *module*, which takes the outputs of the provider and then deploys the resources using standard Azure providers (AzureRM/AzAPI).

None of these items exist yet! But we would like to show you how they could work to get feedback 😃

We have provided three directories as examples:

- [Deploying ALZ defaults](https://github.com/Azure/terraform-azurerm-alz/blob/main/alz-defaults)
- [Customizing management groups](https://github.com/Azure/terraform-azurerm-alz/tree/main/customizing-mgs)
- [Provider details](https://github.com/Azure/terraform-azurerm-alz/tree/main/provider)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

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
