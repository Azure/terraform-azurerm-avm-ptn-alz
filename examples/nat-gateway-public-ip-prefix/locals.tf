# Shared locals for the NAT Gateway public IP prefix example, kept in a
# single file so `main.nat_gateway.tf` can stay focused on resource
# definitions.

locals {
  # Centralizing the API versions used by the resources in main.nat_gateway.tf
  # makes future version bumps easier to manage consistently.
  nat_gateway_example_resource_group_api_version    = "2024-11-01"
  nat_gateway_example_network_resources_api_version = "2024-05-01"
}

locals {
  # Terraform has no built-in `cidrcontains` function, so containment is
  # checked by re-masking the subnet's network address to the virtual
  # network's prefix length using `cidrhost()`, and comparing the result with
  # the virtual network's own network address; if the subnet is contained
  # within the virtual network, the two addresses will match. Each step is
  # individually wrapped in `try()`, resulting in `null` if it fails (e.g. a
  # malformed CIDR range), so that the `precondition` on
  # `azapi_resource.nat_gateway_example_subnet` fails with a clear error
  # message instead of an unclear error from `split()`/`cidrhost()`. (The
  # variables are also separately validated to be well-formed CIDR ranges as
  # a first line of defense.)
  #
  # Example (values from this file's defaults):
  #   subnet = "10.20.0.0/24", virtual network = "10.20.0.0/16"
  #   -> subnet re-masked to /16 = "10.20.0.0/16", vnet network address = "10.20.0.0"
  #   -> addresses match and the subnet prefix length (24) >= vnet prefix
  #      length (16), so the subnet is contained in the virtual network.
  nat_gateway_example_subnet_prefix_length          = try(tonumber(split("/", var.nat_gateway_example_subnet_address_prefix)[1]), null)
  nat_gateway_example_virtual_network_prefix_length = try(tonumber(split("/", var.nat_gateway_example_virtual_network_address_space)[1]), null)

  # The subnet's network address, re-masked to the virtual network's prefix
  # length.
  nat_gateway_example_subnet_network_address_at_virtual_network_mask = try(
    cidrhost(
      "${cidrhost(var.nat_gateway_example_subnet_address_prefix, 0)}/${local.nat_gateway_example_virtual_network_prefix_length}",
      0
    ),
    null
  )
  nat_gateway_example_virtual_network_network_address = try(cidrhost(var.nat_gateway_example_virtual_network_address_space, 0), null)

  nat_gateway_example_subnet_contained_in_virtual_network = (
    local.nat_gateway_example_subnet_prefix_length != null &&
    local.nat_gateway_example_virtual_network_prefix_length != null &&
    local.nat_gateway_example_subnet_network_address_at_virtual_network_mask != null &&
    local.nat_gateway_example_virtual_network_network_address != null &&
    local.nat_gateway_example_subnet_prefix_length >= local.nat_gateway_example_virtual_network_prefix_length &&
    local.nat_gateway_example_subnet_network_address_at_virtual_network_mask == local.nat_gateway_example_virtual_network_network_address
  )
}
