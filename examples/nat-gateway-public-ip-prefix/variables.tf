variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable telemetry for the module."
  nullable    = false
}

variable "location" {
  type        = string
  default     = "northeurope"
  description = <<DESCRIPTION
The Azure region used for the ALZ architecture resources and, when `enable_nat_gateway_example` is `true`, for the NAT Gateway example network resources.

The existing public IP prefix referenced by `existing_public_ip_prefix_id` must be deployed to this same region.
DESCRIPTION
  nullable    = false
}

variable "enable_nat_gateway_example" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Set to `true` to additionally deploy an example network (resource group, virtual network and subnet) with a Standard NAT Gateway associated with the subnet.

The NAT Gateway is configured with a Standard static public IP address allocated from the existing public IP prefix supplied via `existing_public_ip_prefix_id`.

These resources are created independently of, and are not a dependency of, `module.alz_architecture`; they only demonstrate how you can bring your own public IP prefix to a NAT Gateway alongside the ALZ deployment.
DESCRIPTION
  nullable    = false
}

variable "existing_public_ip_prefix_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The resource ID of an existing `Microsoft.Network/publicIPPrefixes` resource to allocate the NAT Gateway's public IP address from.

Required when `enable_nat_gateway_example` is `true`. The public IP prefix must exist in the same subscription and the same Azure region (see `location`) as the public IP address that will be created from it.

Example: `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/pip-prefix-example`
DESCRIPTION
  nullable    = true

  validation {
    condition     = var.existing_public_ip_prefix_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[a-zA-Z0-9_.()-]+/providers/Microsoft\\.Network/publicIPPrefixes/[a-zA-Z0-9_.-]+$", var.existing_public_ip_prefix_id))
    error_message = "`existing_public_ip_prefix_id` must be `null` or a valid `Microsoft.Network/publicIPPrefixes` resource ID, e.g. `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/pip-prefix-example`."
  }

  # Cross-variable validation (supported since Terraform 1.9, which this
  # example requires) so that a missing prefix ID is reported as a clear,
  # early plan-time variable validation error rather than only being caught
  # later by the `precondition` on `azapi_resource.nat_gateway_example_public_ip`.
  validation {
    condition     = var.enable_nat_gateway_example ? var.existing_public_ip_prefix_id != null : true
    error_message = "`existing_public_ip_prefix_id` must be supplied when `enable_nat_gateway_example` is `true`."
  }
}

variable "nat_gateway_example_network_resource_group_name" {
  type        = string
  default     = "rg-alz-example-nat-gateway"
  description = "The name of the resource group created to hold the example NAT Gateway network resources when `enable_nat_gateway_example` is `true`."
  nullable    = false
}

variable "nat_gateway_example_virtual_network_name" {
  type        = string
  default     = "vnet-alz-example-nat-gateway"
  description = "The name of the virtual network created for the NAT Gateway example when `enable_nat_gateway_example` is `true`."
  nullable    = false
}

variable "nat_gateway_example_virtual_network_address_space" {
  type        = string
  default     = "10.20.0.0/16"
  description = "The address space of the virtual network created for the NAT Gateway example when `enable_nat_gateway_example` is `true`."
  nullable    = false

  validation {
    condition     = can(cidrhost(var.nat_gateway_example_virtual_network_address_space, 0))
    error_message = "`nat_gateway_example_virtual_network_address_space` must be a valid IPv4 CIDR range, e.g. `10.20.0.0/16`."
  }
}

variable "nat_gateway_example_subnet_name" {
  type        = string
  default     = "snet-alz-example-nat-gateway"
  description = "The name of the subnet associated with the example NAT Gateway when `enable_nat_gateway_example` is `true`."
  nullable    = false
}

variable "nat_gateway_example_subnet_address_prefix" {
  type        = string
  default     = "10.20.0.0/24"
  description = "The address prefix of the subnet associated with the example NAT Gateway when `enable_nat_gateway_example` is `true`."
  nullable    = false

  validation {
    condition     = can(cidrhost(var.nat_gateway_example_subnet_address_prefix, 0))
    error_message = "`nat_gateway_example_subnet_address_prefix` must be a valid IPv4 CIDR range, e.g. `10.20.0.0/24`."
  }
}
