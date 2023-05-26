# provider

A new provider could be used to process the data required to create resources and their dependencies.
This provider would be configured using the `provider {}` block.

The provider will contain (baked into the binary) the ALZ reference architecture, consisting of:

- Management group archetypes
- Custom policy definitions
- Policy assignments
- Custom role definitions
- Role assignments

Example of provider configuration:

```terraform
provider "alz" {
  custom_lib_directory                   = "./lib"
  custom_lib_overwrites_provider_content = true # if the artifects in the custom lib directory have the same `name` property as those included in the provider, should they overwrite?
  default_location                       = "useast2"
}
```

Items included in the provider must be known at init time, therefore we shouldn't include resoruce ids for things like LA workspaces, etc.
These will have to be handled in resources or data sources.
