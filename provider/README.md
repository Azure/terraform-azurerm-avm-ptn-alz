# provider

A new provider could be used to process the data required to create resources and their dependencies.
This provider would be configured using the `provider {}` block.

The provider will contain (baked into the binary) the ALZ reference architecture, consisting of:

- Management group archetypes
- Custom policy definitions
- Policy assignments
- Custom role definitions

Example of provider configuration:

```terraform
provider "alz" {
  lib_directory                             = "./lib"
  lib_directory_overwrites_provider_content = true # if the artifacts in the custom lib directory have the same `name` property as those included in the provider, should they overwrite?
  default_location                          = "useast2"
}
```

Items included in the provider must be known at init time, therefore we shouldn't include resource ids for things like LA workspaces, etc.
These will have to be handled in resources or data sources.

## constraints

### policy definition name uniqueness

This is because we must be able to identity a definition from a custom policy set, which will be defined in JSON by resource id, however the full resource id cannot be known, hence we can only take the last segment and look this up in a map within the provider.

## provider schema

The proposed schema for the `provider {}` block.

| property                                    | type     | description                                                                             | optional |
|---------------------------------------------|----------|-----------------------------------------------------------------------------------------|----------|
| `lib_directory`                             | `string` | The location of the custom directory containing custom policy & policy set definitions. | yes      |
| `lib_directory_overwrites_provider_content` | `bool`   | Does an artifact with the same name overwrite the provider content?                     | yes      |
| `default_location`                          | `string` | The default location for resources contained within this module.                        | yes      |
| `default_log_analytics_workspace_id`        | `string` | The default resource id for the log analytics workspace.                                | yes      |
| `default_non_compliance_message`            | `string` | The default non-compliance message for policy assignments workspace.                    | yes      |

## archetype data source schema

The proposed provider schema for the `alz_archetype` data source is below:

| property                       | type                           | description                                                                                                                                            | optional |
|--------------------------------|--------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| `name`                         | `string`                       | The name of the management group                                                                                                                       | no       |
| `parent_id`                    | `string`                       | The name of the parent management group                                                                                                                | no       |
| `base_archetype`               | `string`                       | The name of the archetype that is built into the provider (use `empty` to completely customize a mg).                                                  | no       |
| `display_name`                 | `string`                       | The display name of the management group                                                                                                               | yes      |
| `policy_assignments_to_add`    | `map[string]policy_assignmnet` | The additional or overwritten policy assignments at this scope. See [policy_assigment](#policy_assignment-schema). The map key is the assignment name. | yes      |
| `policy_assignments_to_remove` | `[]string`                     | The list of assignments to remove from the archetype                                                                                                   | yes      |
| `policy_definition_identity`
| `policy_definitions_to_add` | `[]string` | The list of policy definition names to add from the `lib_directory` | yes |
| `policy_definitions_to_remove` | `[]string` | The list of policy definition names to remove from the archetype | yes |
| `policy_set_definitions_to_add` | `[]string` | The list of policy set definition names to add from the `lib_directory` | yes |
| `policy_set_definitions_to_remove` | `[]string` | The list of policy set definition names to remove from the archetype | yes |
| `role_assignments_to_add` | `[]role_assignment` a list of the role assignments to add at scope | See [role_assignment](#role_assignment-schema) | yes |

### policy_assignment schema

Each policy assignment has the following properties:

| property                  | type                       | description                                                                                          | optional |
|---------------------------|----------------------------|------------------------------------------------------------------------------------------------------|----------|
| `display_name`            | `string`                   | The display name of the policy assignment.                                                           | no       |
| `policy_definition_name`  | `string`                   | The name of the policy definition.                                                                   | no       |
| `description`             | `string`                   | The description of the policy assignment.                                                            | yes      |
| `enforcement_mode`        | `string`                   | The enforcement_mode of the policy assignment, "Default" or "DoNotEnforce".                          | yes      |
| `managed_identity`        | `string`                   | The managed identity type, e.g. `"SystemAssigned", "UserAssigned"`.                                  | yes      |
| `managed_identity_ids`    | `[]string`                 | The user managed identity resource ids type.                                                         | yes      |
| `non_compliance_messages` | `[]non_compliance_message` | A list of non-compliance messages. See [non_compliance_message](#non_compliance_message-schema).     | yes      |
| `overrides`               | `[]override`               | A list of policy assignment overrides. See [override](#override-schema).                             | yes      |
| `parameters`              | `map[string]any`           | A map of the policy parameters keyed by parameter name.                                              | yes      |
| `resource_selectors`      | `map[string][]selector`    | A map of a list of resource selectors, keyed by the selector name. See [selector](#selector-schema). | yes      |

### non_compliance_message schema

| property                         | type     | description                                                                     | optional |
|----------------------------------|----------|---------------------------------------------------------------------------------|----------|
| `message`                        | `string` | The non-compliance message, e.g. `"This is a non-compliant resource."`.         | no       |
| `policy_definition_reference_id` | `string` | The policy definition reference id, e.g. `"my_ref"`. Note, not the resource id. | no       |

### override schema

| property   | type       | description                                              | optional |
|------------|------------|----------------------------------------------------------|----------|
| `kind`     | `string`   | The override kind, e.g. `"policyEffect"`.                | no       |
| `selector` | `selector` | The selector, see [selector](#selector-schema).          | no       |
| `value`    | `string`   | The value to be used in the override, e.g. `"Disabled"`. | no       |

### selector schema

| property | type       | description                                  | optional                     |
|----------|------------|----------------------------------------------|------------------------------|
| `in`     | `[]string` | A list of values to match.                   | yes (conflicts with `notIn`) |
| `kind`   | `string`   | The selector kind, e.g. `"resourceLocation"` | no                           |
| `notIn`  | `[]string` | The values to not match.                     | Yes (conflicts with `in`)    |

### role_assignment schema

| property       | type     | description                        | optional |
|----------------|----------|------------------------------------|----------|
| `definition`   | `string` | The definition name or resource id | no       |
| `principal_id` | `string` | The AAD object id to assign.       | no       |
