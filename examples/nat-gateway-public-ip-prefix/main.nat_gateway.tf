# This file demonstrates how to bring your own existing Azure Public IP Prefix
# to allocate a public IP address for a Standard NAT Gateway, and how to
# associate that NAT Gateway with a subnet.
#
# `module.alz_architecture` has no input for networking resources, so these
# resources are created independently, alongside the ALZ deployment, and are
# not a dependency of the module. Set `enable_nat_gateway_example = true` and
# supply `existing_public_ip_prefix_id` to deploy them.
#
# All resources below share the same `count = var.enable_nat_gateway_example
# ? 1 : 0` condition, so cross-references via `one(...)` always resolve to
# exactly one instance whenever they are evaluated (matching the convention
# used elsewhere in this module, e.g. `main.telemetry.tf`).
#
# API versions and CIDR-containment validation logic are defined in
# `locals.tf` to keep this file focused on resource definitions.

resource "azapi_resource" "nat_gateway_example_resource_group" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Resources/resourceGroups@${local.nat_gateway_example_resource_group_api_version}"
  name      = var.nat_gateway_example_network_resource_group_name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = var.location

  response_export_values = []
}

resource "azapi_resource" "nat_gateway_example_public_ip" {
  count = var.enable_nat_gateway_example ? 1 : 0

  type      = "Microsoft.Network/publicIPAddresses@${local.nat_gateway_example_network_resources_api_version}"
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
      # public IP address. This is only validated by Azure at apply time;
      # if `existing_public_ip_prefix_id` refers to a prefix in a different
      # region or subscription, the API call below will fail.
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

  type      = "Microsoft.Network/natGateways@${local.nat_gateway_example_network_resources_api_version}"
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

  type      = "Microsoft.Network/virtualNetworks@${local.nat_gateway_example_network_resources_api_version}"
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

# The NAT Gateway is associated with the subnet at creation time by setting
# `properties.natGateway.id` in the subnet body.
resource "azapi_resource" "nat_gateway_example_subnet" {
  count = var.enable_nat_gateway_example ? 1 : 0

  # `Microsoft.Network/virtualNetworks/subnets` is a child resource type and
  # does not accept a `location` property, unlike the other resources in this
  # file.
  type      = "Microsoft.Network/virtualNetworks/subnets@${local.nat_gateway_example_network_resources_api_version}"
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
