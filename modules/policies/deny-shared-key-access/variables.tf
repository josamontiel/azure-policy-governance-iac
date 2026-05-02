variable "management_group_id" {
  description = "The full resource ID of the management group where this policy definition will live."
  type        = string
}

variable "policy_name" {
  description = "Internal name of the policy definition (used in resource IDs)."
  type        = string
  default     = "deny-shared-key-access"
}

variable "display_name" {
  description = "Human-readable display name shown in the Azure portal."
  type        = string
  default     = "Deny Storage Accounts Without Shared Key Access Disabled"
}
