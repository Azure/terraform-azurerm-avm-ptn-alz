output "id" {
  value       = azapi_resource.this.id
  description = "The Azure resource id of the resource."
}

output "output" {
  value       = azapi_resource.this.output
  description = "The output values of the resource as defined by `response_export_values`."
}
