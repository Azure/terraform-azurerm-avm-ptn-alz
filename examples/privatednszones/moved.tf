moved {
  from = module.private_dns_zones.azurerm_resource_group.this[0]
  # Continue through the resource-group module's provider and count migration.
  to = module.resource_group.azurerm_resource_group.this
}
