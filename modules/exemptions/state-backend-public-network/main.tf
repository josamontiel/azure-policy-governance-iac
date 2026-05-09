resource "azurerm_resource_policy_exemption" "state_backend_public_network" {
  name                            = var.exemption_name
  resource_id                     = var.scope_id
  policy_assignment_id            = var.policy_assignment_id
  exemption_category              = var.exemption_category
  display_name                    = var.display_name
  description                     = var.description
  expires_on                      = var.expires_on
  policy_definition_reference_ids = var.policy_definition_reference_ids
  metadata                        = jsonencode(var.metadata)
}
