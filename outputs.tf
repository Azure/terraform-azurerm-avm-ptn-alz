output "management_group_name" {
  description = "The id of the management group."
  value       = azurerm_management_group.this.name
}
