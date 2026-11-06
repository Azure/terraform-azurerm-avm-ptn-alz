data "azapi_client_config" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

locals {
  main_location = var.location
}

removed {
  from = modtm_telemetry.telemetry
  lifecycle {
    destroy = false
  }
}

removed {
  from = random_uuid.telemetry
  lifecycle {
    destroy = false
  }
}

locals {
  avm_metadata                = jsondecode(file("${path.module}/metadata.json"))
  avm_telemetry_manifest_path = "${path.root}/.terraform/modules/modules.json"
  avm_telemetry_modules       = fileexists(local.avm_telemetry_manifest_path) ? jsondecode(file(local.avm_telemetry_manifest_path)).Modules : []
  avm_telemetry_module_entry  = try(one([for module in local.avm_telemetry_modules : module if module.Dir == path.module]), null)
  avm_module_version          = try(local.avm_telemetry_module_entry.Version, "")
  avm_module_source           = try(local.avm_telemetry_module_entry.Source, "")

}

locals {
  avm_module_source_type = (
    can(regex("^registry[.]terraform[.]io/", local.avm_module_source)) ? "t" :
    can(regex("^registry[.]opentofu[.]org/", local.avm_module_source)) ? "o" :
    can(regex("^git::", local.avm_module_source)) ? "g" :
    "x"
  )
}

locals {
  avm_telemetry_additional_content_name = var.telemetry_additional_content == null ? "" : join("-", flatten([
    for key in sort(keys(var.telemetry_additional_content)) :
    [key, var.telemetry_additional_content[key] == null ? "" : var.telemetry_additional_content[key]]
  ]))
}

locals {
  avm_telemetry_version_token = replace(coalesce(local.avm_module_version, "0.0.0"), ".", "-")
}

resource "terraform_data" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

resource "azapi_resource" "telemetry" {
  count = var.enable_telemetry ? 1 : 0

  location  = local.main_location
  name      = format("%s%s", join(".", [local.avm_metadata.telemetryIdPrefix, local.avm_telemetry_version_token, local.avm_module_source_type, substr(sha1(terraform_data.telemetry[0].id), 0, 4)]), local.avm_telemetry_additional_content_name == "" ? "" : "-${local.avm_telemetry_additional_content_name}")
  parent_id = one(data.azapi_client_config.telemetry).subscription_resource_id
  type      = "Microsoft.Resources/deployments@2025-04-01"
  body = {
    properties = {
      mode = "Incremental"
      template = {
        "$schema"      = "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
        contentVersion = "1.0.0.0"
        resources      = []
        outputs = {
          telemetry = {
            type  = "String"
            value = "For more information, see https://aka.ms/avm/TelemetryInfo"
          }
          apply_id = {
            type  = "String"
            value = plantimestamp()
          }
        }
      }
    }
  }
  response_export_values = []

  lifecycle {
    precondition {
      condition     = length(local.avm_metadata.telemetryIdPrefix) + length(local.avm_telemetry_version_token) + 8 + (local.avm_telemetry_additional_content_name == "" ? 0 : 1 + length(local.avm_telemetry_additional_content_name)) <= 64 && can(regex("^[A-Za-z0-9_-]+$", local.avm_telemetry_version_token)) && (local.avm_telemetry_additional_content_name == "" || can(regex("^[A-Za-z0-9_.()-]+$", local.avm_telemetry_additional_content_name)))
      error_message = "The telemetry deployment name must fit Azure's 64-character limit and contain only letters, numbers, periods, underscores, hyphens, and parentheses."
    }
  }
}
