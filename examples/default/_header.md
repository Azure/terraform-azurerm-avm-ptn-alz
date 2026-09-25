# Deploying the ALZ Reference Architecture

This example shows how to deploy the ALZ reference architecture.

## Optional: NAT Gateway with a public IP from an existing public IP prefix

`module.alz_architecture` does not manage networking resources, so it has no input for a NAT Gateway or a public IP. This example optionally demonstrates, alongside (and independently of) the ALZ deployment, how to:

- Create a Standard static public IP address allocated from an existing Azure Public IP Prefix (`Microsoft.Network/publicIPPrefixes`).
- Create a Standard NAT Gateway that uses that public IP address.
- Associate the NAT Gateway with a subnet in an example virtual network.

To deploy these resources, set `enable_nat_gateway_example = true` and supply `existing_public_ip_prefix_id` with the resource ID of your existing public IP prefix, for example:

```hcl
enable_nat_gateway_example   = true
existing_public_ip_prefix_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/pip-prefix-example"
```

> [!IMPORTANT]
> The public IP prefix must exist in the same subscription and the same Azure region (`location`) as the public IP address that will be created from it.

These resources are created independently of `module.alz_architecture` and are not configured as a dependency of it, since the `alz` provider has special plan-time behaviour that does not support arbitrary `depends_on` relationships on the module.
