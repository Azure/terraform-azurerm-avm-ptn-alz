output "identity" {
  description = "The identity configuration of the resource."
  value       = try(azapi_resource.this.identity[0], null)
}

output "name" {
  description = "The name of the resource."
  value       = azapi_resource.this.name
}

output "output" {
  description = "The output values of the resource as defined by `response_export_values`."
  value       = azapi_resource.this.output
}

output "resource_id" {
  description = "The Azure resource id of the resource."
  value       = azapi_resource.this.id
}
