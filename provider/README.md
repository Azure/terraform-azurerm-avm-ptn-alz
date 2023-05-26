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

## provider schema

The proposed schema for the `provider {}` block.



## archetype data source schema

The proposed provider schema for the `alz_archetype` data source is below:

| property | type | description | optional |
| - | - | - | - |
| `name` | `string` | The name of the management group | no |
| `parent_id` | `string` | The name of the parent management group | no |
| `base_archetype` | `string` | The name of the archetype that is built into the provider (use `empty` to completely customize a mg). | no |
| `display_name` | `string` | The display name of the management group | yes |
| policy_assignments_to_add | `map[string]policy_assignmnet` | The additional or overwritten policy assignments at this scope. See [policy_assigment](#policy_assignment schema). | yes |
| `policy_assignments_to_remove` | `[]string` | The list of assignments to remove from the archetype | yes |
| `policy_definitions_to_add` | `[]string` | The list of policy definition names to add from the `lib_directory` | yes |
| `policy_definitions_to_remove` | `[]string` | The list of policy definition names to remove from the archetype | yes |
| `policy_set_definitions_to_add` | `[]string` | The list of policy set definition names to add from the `lib_directory` | yes |
| `policy_set_definitions_to_remove` | `[]string` | The list of policy set definition names to remove from the archetype | yes |


### policy_assignment schema
