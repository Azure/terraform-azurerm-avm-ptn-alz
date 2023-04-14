provider "alz" {
  lib_directory    = "./lib"
  default_location = "useast2"
}

# get the tenant id to use for the tenant root management group
data "azurerm_client_config" "current" {}
