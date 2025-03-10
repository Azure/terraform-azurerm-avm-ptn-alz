variable "management_group_role_assignments" {
  type = map(object({
    management_group_name                  = string
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `management_group_name` - The name of the management group to assign the role to.
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) No effect when using AzAPI.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

We recommend using role assignment conditions to restrict privileged assignments. A sensible default is to use the `condition` attribute to restrict the roles that can be assigned. The following example will restrict the role assignment to prevent the `Owner`, `Role Based Access Control Administrator`, and `User Access Administrator` roles being assigned:

```text
"((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'}))OR(@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId]ForAnyOfAllValues:GuidNotEquals{8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}))AND((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'}))OR(@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId]ForAnyOfAllValues:GuidNotEquals{8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}))"
```
DESCRIPTION
}

variable "role_assignment_definition_lookup_enabled" {
  type        = bool
  description = <<DESCRIPTION
A control to disable the lookup of role definitions when creating role assignments.
If you disable this then all role assignments must be supplied with a `role_definition_id_or_name` that is a valid role definition ID.
DESCRIPTION
  default     = true
}
