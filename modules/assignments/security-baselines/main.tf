# The assignment itself - binds the initiative to the management group scope
# with explicit parameter values and a system-assigned managed identity for
# DeployIfNotExists remediation.
resource "azurerm_management_group_policy_assignment" "security_baselines" {
  name                 = var.assignment_name
  display_name         = var.display_name
  description          = var.description
  management_group_id  = var.management_group_id
  policy_definition_id = var.initiative_id
  enforce              = true
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
    allowedLocations = {
      value = var.allowed_locations
    }
    requiredTagName = {
      value = var.required_tag_name
    }
    requiredTagValue = {
      value = var.required_tag_value
    }
    diagnosticSettingsEffect = {
      value = var.diagnostic_settings_effect
    }
    publicNetworkAccessEffect = {
      value = var.public_network_access_effect
    }
  })

  non_compliance_message {
    content = var.non_compliance_message
  }
}

# Role assignment: Log Analytics Contributor on the managed identity.
# Required for the diagnostic settings DINE policy to write to the workspace.
resource "azurerm_role_assignment" "log_analytics_contributor" {
  scope                = var.management_group_id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_management_group_policy_assignment.security_baselines.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role assignment: Monitoring Contributor on the managed identity.
# Required for the diagnostic settings DINE policy to create diagnostic
# settings on target resources.
resource "azurerm_role_assignment" "monitoring_contributor" {
  scope                = var.management_group_id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_management_group_policy_assignment.security_baselines.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
