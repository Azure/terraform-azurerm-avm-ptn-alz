data "alz_architecture" "this" {
  name                     = var.architecture_name
  root_management_group_id = var.parent_resource_id
  location                 = var.location
}
