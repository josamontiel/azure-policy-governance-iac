locals {
  # Built-in policy definition IDs. These are stable, Microsoft-published values.
  builtin_required_tag_policy_id        = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
  builtin_diagnostic_settings_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/59759c62-9a22-4cdf-ae64-074495983fef"
  builtin_public_network_access_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
  builtin_allowed_locations_policy_id   = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
}

resource "azurerm_policy_set_definition" "security_baselines" {
  name                = var.initiative_name
  policy_type         = "Custom"
  display_name        = var.display_name
  description         = var.description
  management_group_id = var.management_group_id

  metadata = jsonencode({
    category = "Security"
    version  = "1.1.0"
  })

  # Initiative-level parameters that are passed through to underlying policies.
  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      type = "String"
      metadata = {
        displayName = "Log Analytics Workspace ID"
        description = "Full resource ID of the workspace that diagnostic settings will forward to."
      }
    }
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "List of regions where resource deployment is permitted."
      }
    }
    requiredTagName = {
      type = "String"
      metadata = {
        displayName = "Required Tag Name"
        description = "Tag key required on every resource."
      }
    }
    requiredTagValue = {
      type = "String"
      metadata = {
        displayName = "Required Tag Value"
        description = "Tag value required for the required tag."
      }
    }
    diagnosticSettingsEffect = {
      type          = "String"
      allowedValues = ["DeployIfNotExists", "AuditIfNotExists", "Disabled"]
      metadata = {
        displayName = "Diagnostic Settings Effect"
        description = "Whether to deploy, audit, or disable the diagnostic settings rule."
      }
    }
    publicNetworkAccessEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      metadata = {
        displayName = "Public Network Access Effect"
        description = "Whether to audit, deny, or disable the public network access rule."
      }
    }
  })

  # Custom: Deny Shared Key Access (no parameters wired through)
  policy_definition_reference {
    policy_definition_id         = var.shared_key_policy_id
    reference_id                 = "Block Public Blob Storage_1"
    parameter_values             = jsonencode({})
  }

  # Built-in: Require a tag and its value on resources
  policy_definition_reference {
    policy_definition_id = local.builtin_required_tag_policy_id
    reference_id         = "Require a tag and its value on resources_1"
    parameter_values = jsonencode({
      tagName  = { value = "[parameters('requiredTagName')]" }
      tagValue = { value = "[parameters('requiredTagValue')]" }
    })
  }

  # Built-in: Configure diagnostic settings for Storage Accounts
  policy_definition_reference {
    policy_definition_id = local.builtin_diagnostic_settings_policy_id
    reference_id         = "Configure diagnostic settings for Storage Accounts to Log Analytics workspace_1"
    parameter_values = jsonencode({
      logAnalytics = { value = "[parameters('logAnalyticsWorkspaceId')]" }
      effect       = { value = "[parameters('diagnosticSettingsEffect')]" }
    })
  }

  # Built-in: Storage accounts should disable public network access
  policy_definition_reference {
    policy_definition_id = local.builtin_public_network_access_policy_id
    reference_id         = "Storage accounts should disable public network access_1"
    parameter_values = jsonencode({
      effect = { value = "[parameters('publicNetworkAccessEffect')]" }
    })
  }

  # Built-in: Allowed locations
  policy_definition_reference {
    policy_definition_id = local.builtin_allowed_locations_policy_id
    reference_id         = "Allowed locations_1"
    parameter_values = jsonencode({
      listOfAllowedLocations = { value = "[parameters('allowedLocations')]" }
    })
  }
}
