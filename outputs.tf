output "management_group_resource_id" {
  description = "The resource id of the created management group."
  value       = azurerm_management_group.this.id
}
