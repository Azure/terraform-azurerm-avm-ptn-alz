mock_provider "azapi" {}

override_module {
  target = module.alz_architecture
}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = length(azapi_resource.nat_gateway_example_resource_group) == 0
    error_message = "No NAT Gateway example resources should be planned when `enable_nat_gateway_example` is `false` (the default)."
  }
}

run "enabled_with_valid_inputs" {
  command = plan

  variables {
    enable_nat_gateway_example   = true
    existing_public_ip_prefix_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/pip-prefix-example"
  }

  assert {
    condition     = length(azapi_resource.nat_gateway_example_subnet) == 1
    error_message = "The NAT Gateway example subnet should be planned when `enable_nat_gateway_example` is `true` and a valid public IP prefix ID is supplied."
  }
}

run "enabled_without_public_ip_prefix_id_fails" {
  command = plan

  variables {
    enable_nat_gateway_example = true
  }

  expect_failures = [
    azapi_resource.nat_gateway_example_public_ip,
  ]
}

run "enabled_with_subnet_outside_virtual_network_fails" {
  command = plan

  variables {
    enable_nat_gateway_example                = true
    existing_public_ip_prefix_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/pip-prefix-example"
    nat_gateway_example_subnet_address_prefix = "10.99.0.0/24"
  }

  expect_failures = [
    azapi_resource.nat_gateway_example_subnet,
  ]
}
