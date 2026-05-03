output "id" {
  description = "The full resource ID of the created initiative."
  value       = azurerm_policy_set_definition.security_baselines.id
}

output "name" {
  description = "The internal name of the initiative."
  value       = azurerm_policy_set_definition.security_baselines.name
}

output "display_name" {
  description = "The display name of the initiative."
  value       = azurerm_policy_set_definition.security_baselines.display_name
}
