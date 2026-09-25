# This file demonstrates how to bring your own existing Azure Public IP Prefix
# to allocate a public IP address for a Standard NAT Gateway, and how to
# associate that NAT Gateway with a subnet.
#
# `module.alz_architecture` has no input for networking resources, so these
# resources are created independently, alongside the ALZ deployment, and are
# not a dependency of the module. Set `enable_nat_gateway_example = true` and
# supply `existing_public_ip_prefix_id` to deploy them.

resource "azapi_resource" "nat_gateway_example_resource_group" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  name      = var.nat_gateway_example_network_resource_group_name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = var.location

  response_export_values = []
}

resource "azapi_resource" "nat_gateway_example_public_ip" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Network/publicIPAddresses@2024-05-01"
  name      = "pip-${var.nat_gateway_example_subnet_name}"
  parent_id = one(azapi_resource.nat_gateway_example_resource_group).id
  location  = var.location

  body = {
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    properties = {
      publicIPAddressVersion   = "IPv4"
      publicIPAllocationMethod = "Static"
      # Allocates the public IP address from the existing public IP prefix.
      # The prefix must be in the same subscription and region as this
      # public IP address.
      publicIPPrefix = {
        id = var.existing_public_ip_prefix_id
      }
    }
  }

  response_export_values = [
    "properties.ipAddress",
  ]

  lifecycle {
    precondition {
      condition     = var.existing_public_ip_prefix_id != null
      error_message = "`existing_public_ip_prefix_id` must be supplied when `enable_nat_gateway_example` is `true`."
    }
  }
}

resource "azapi_resource" "nat_gateway_example_nat_gateway" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Network/natGateways@2024-05-01"
  name      = "nat-${var.nat_gateway_example_subnet_name}"
  parent_id = one(azapi_resource.nat_gateway_example_resource_group).id
  location  = var.location

  body = {
    sku = {
      name = "Standard"
    }
    properties = {
      publicIpAddresses = [
        {
          id = one(azapi_resource.nat_gateway_example_public_ip).id
        }
      ]
    }
  }

  response_export_values = []
}

resource "azapi_resource" "nat_gateway_example_virtual_network" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = var.nat_gateway_example_virtual_network_name
  parent_id = one(azapi_resource.nat_gateway_example_resource_group).id
  location  = var.location

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [
          var.nat_gateway_example_virtual_network_address_space,
        ]
      }
    }
  }

  response_export_values = []
}

locals {
  # Terraform has no built-in `cidrcontains` function, so containment is
  # checked by re-masking the subnet's network address to the virtual
  # network's prefix length using `cidrhost()`, and comparing the result with
  # the virtual network's own network address; if the subnet is contained
  # within the virtual network, the two addresses will match. The whole
  # computation is wrapped in a single `try()`, resulting in `null` if any
  # step fails (e.g. a malformed CIDR range), so that the `precondition`
  # below fails with a clear error message instead of an unclear error from
  # `split()`/`cidrhost()`. (The variables are also separately validated to
  # be well-formed CIDR ranges as a first line of defense.)
  nat_gateway_example_cidr_containment_check = try(
    {
      subnet_prefix_length          = tonumber(split("/", var.nat_gateway_example_subnet_address_prefix)[1])
      virtual_network_prefix_length = tonumber(split("/", var.nat_gateway_example_virtual_network_address_space)[1])
      # The subnet's network address, re-masked to the virtual network's
      # (shorter, or equal) prefix length.
      subnet_network_address_at_virtual_network_mask = cidrhost(
        "${cidrhost(var.nat_gateway_example_subnet_address_prefix, 0)}/${tonumber(split("/", var.nat_gateway_example_virtual_network_address_space)[1])}",
        0
      )
      virtual_network_network_address = cidrhost(var.nat_gateway_example_virtual_network_address_space, 0)
    },
    null
  )

  nat_gateway_example_subnet_contained_in_virtual_network = (
    local.nat_gateway_example_cidr_containment_check != null &&
    local.nat_gateway_example_cidr_containment_check.subnet_prefix_length >= local.nat_gateway_example_cidr_containment_check.virtual_network_prefix_length &&
    local.nat_gateway_example_cidr_containment_check.subnet_network_address_at_virtual_network_mask == local.nat_gateway_example_cidr_containment_check.virtual_network_network_address
  )
}

# The NAT Gateway is associated with the subnet at creation time by setting
# `properties.natGateway.id` in the subnet body.
resource "azapi_resource" "nat_gateway_example_subnet" {
  count = var.enable_nat_gateway_example ? 1 : 0

  # `Microsoft.Network/virtualNetworks/subnets` is a child resource type and
  # does not accept a `location` property, unlike the other resources in this
  # file.
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = var.nat_gateway_example_subnet_name
  parent_id = one(azapi_resource.nat_gateway_example_virtual_network).id

  body = {
    properties = {
      addressPrefix = var.nat_gateway_example_subnet_address_prefix
      natGateway = {
        id = one(azapi_resource.nat_gateway_example_nat_gateway).id
      }
    }
  }

  response_export_values = []

  lifecycle {
    precondition {
      condition     = local.nat_gateway_example_subnet_contained_in_virtual_network
      error_message = "`nat_gateway_example_subnet_address_prefix` must be a valid CIDR range contained within `nat_gateway_example_virtual_network_address_space`."
    }
  }
}
