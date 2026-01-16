# Deploying to a Specific Management Group and moving the subscriptions back there on Destroy

This example shows how to deploy to a specific management group by setting the `parent_resource_id` variable to the desired management group ID. It also demonstrates how to move the subscriptions back to that same management group when the ALZ resources are destroyed by setting the `subscription_placement_destroy_target_management_group_id` variable.
