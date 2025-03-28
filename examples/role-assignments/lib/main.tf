locals {
  architecture_definition_filename          = "test.alz_architecture_definition.yaml"
  architecture_definition_template_filename = "${local.architecture_definition_filename}.tftpl"
}

resource "local_file" "architecture_definition" {
  filename = local.architecture_definition_filename
  content = templatefile("${path.module}/${local.architecture_definition_template_filename}", {
    prefix = var.prefix
  })
}
