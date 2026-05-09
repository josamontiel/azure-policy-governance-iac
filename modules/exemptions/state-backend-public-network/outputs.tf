output "id" {
  description = "The full resource ID of the created exemption."
  value       = azurerm_resource_policy_exemption.state_backend_public_network.id
}

output "name" {
  description = "The internal name of the exemption."
  value       = azurerm_resource_policy_exemption.state_backend_public_network.name
}

output "expires_on" {
  description = "When this exemption expires."
  value       = azurerm_resource_policy_exemption.state_backend_public_network.expires_on
}
