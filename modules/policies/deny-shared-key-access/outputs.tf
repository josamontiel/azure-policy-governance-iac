output "id" {
  description = "The full resource ID of the created policy definition."
  value       = azurerm_policy_definition.deny_shared_key_access.id
}

output "name" {
  description = "The internal name of the policy definition."
  value       = azurerm_policy_definition.deny_shared_key_access.name
}

output "display_name" {
  description = "The display name of the policy definition."
  value       = azurerm_policy_definition.deny_shared_key_access.display_name
}
