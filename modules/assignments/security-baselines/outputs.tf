output "id" {
  description = "The full resource ID of the created assignment."
  value       = azurerm_management_group_policy_assignment.security_baselines.id
}

output "name" {
  description = "The internal name of the assignment."
  value       = azurerm_management_group_policy_assignment.security_baselines.name
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity attached to the assignment."
  value       = azurerm_management_group_policy_assignment.security_baselines.identity[0].principal_id
}
