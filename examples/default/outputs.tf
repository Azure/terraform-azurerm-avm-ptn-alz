output "nat_gateway_example_public_ip_address" {
  value       = try(one(azapi_resource.nat_gateway_example_public_ip).output.properties.ipAddress, null)
  description = "The allocated public IP address of the example NAT Gateway, from the existing public IP prefix. `null` when `enable_nat_gateway_example` is `false`."
}
