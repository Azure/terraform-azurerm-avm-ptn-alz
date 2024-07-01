output "id" {
  value       = azapi_resource.this.id
  description = "The Azure resource id of the resource."
}

output "name" {
  value       = azapi_resource.this.name
  description = "The name of the resource."
}

output "output" {
  value       = azapi_resource.this.output
  description = "The output values of the resource as defined by `response_export_values`."
}

output "identity" {
  value       = try(azapi_resource.this.identity[0], null)
  description = "The identity configuration of the resource."
}
