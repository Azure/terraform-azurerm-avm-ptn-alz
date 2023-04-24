# provider

A new provider could be used to process the data required to create resources and their dependencies.
This provider would be configured using the `provider {}` block.

Example of provider configuration:

```terraform
provider "alz" {
  custom_lib_directory                   = "./lib"
  custom_lib_overwrites_provider_content = true # if the artifects in the custom lib directory have the same `name` property as those included in the provider, should they overwrite?
  default_log_analytics_workspace_id     = "/subscriptions/..."
}
```
