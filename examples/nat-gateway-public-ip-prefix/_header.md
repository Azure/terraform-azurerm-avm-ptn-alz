# Deploying the ALZ Reference Architecture with a NAT Gateway using an existing Public IP Prefix

This example shows how to deploy the ALZ reference architecture, and, alongside it, how to bring your own existing Azure Public IP Prefix to allocate a public IP address for a Standard NAT Gateway that is associated with a subnet.

`module.alz_architecture` has no input for networking resources such as public IPs, public IP prefixes, or NAT Gateways. This example therefore creates those resources independently using `azapi_resource`, alongside (but not as a dependency of) the ALZ deployment.

## Usage

By default, this example only deploys the ALZ reference architecture; the NAT Gateway resources are opt-in and disabled unless `enable_nat_gateway_example` is set to `true`, so that running this example does not require you to have an existing public IP prefix.

To deploy the NAT Gateway example resources (an example resource group, virtual network, subnet, Standard public IP address allocated from your existing public IP prefix, and a Standard NAT Gateway associated with the subnet), set the following variables:

```hcl
enable_nat_gateway_example    = true
existing_public_ip_prefix_id  = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/publicIPPrefixes/<prefix-name>"
location                      = "northeurope"
```

> [!IMPORTANT]
> The existing public IP prefix referenced by `existing_public_ip_prefix_id` **must already exist**, and **must be deployed in the same Azure subscription and the same Azure region** (`location`) as the public IP address that will be allocated from it. Azure does not allow a public IP address to be created from a prefix in a different region or subscription.

The virtual network address space and subnet address prefix used for the example network can also be customized via `nat_gateway_example_virtual_network_address_space` and `nat_gateway_example_subnet_address_prefix` respectively; the subnet must be contained within the virtual network's address space.
