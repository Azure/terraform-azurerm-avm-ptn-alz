# Custom architecture with templating

This example shows how to generate the architecture definition using templating.

Instructions for use:

1. In the `./lib` directory, run terraform init & terraform apply, supplying the value for `var.prefix` when prompted.
2. Observe the generated `custom.alz_architecture_definition.json` file
3. In this example directory, run terraform init & terraform apply, this will use the generated architecture definition to create the resources with the prefix applied to the management group name and display name.
