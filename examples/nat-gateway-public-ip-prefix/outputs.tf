output "nat_gateway_example_public_ip_address" {
  value       = try(one(azapi_resource.nat_gateway_example_public_ip).output.properties.ipAddress, null)
  description = "The public IP address allocated from `existing_public_ip_prefix_id` and assigned to the example NAT Gateway. `null` unless `enable_nat_gateway_example` is `true`."
}

output "nat_gateway_example_nat_gateway_id" {
  value       = try(one(azapi_resource.nat_gateway_example_nat_gateway).id, null)
  description = "The resource ID of the example NAT Gateway. `null` unless `enable_nat_gateway_example` is `true`."
}

output "nat_gateway_example_subnet_id" {
  value       = try(one(azapi_resource.nat_gateway_example_subnet).id, null)
  description = "The resource ID of the example subnet associated with the NAT Gateway. `null` unless `enable_nat_gateway_example` is `true`."
}
