# Configure not_scopes on a policy assignment

This example shows how to exclude one or more scopes (subscriptions, resource groups, or individual resources) from an existing policy assignment that is deployed by the ALZ archetype.

The `not_scopes` field on `policy_assignments_to_modify` accepts a list of resource IDs that will be excluded from policy evaluation, even though they sit beneath the management group where the assignment is applied.
