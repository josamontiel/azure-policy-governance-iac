resource "azurerm_policy_definition" "deny_shared_key_access" {
  name                = var.policy_name
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = var.display_name
  description         = "Audits or denies storage accounts that allow Shared Key authorization. Disabling Shared Key forces Azure AD identity-based access, which provides stronger authentication and clearer audit trails. Aligns with CIS Azure Benchmark 3.8."
  management_group_id = var.management_group_id

  parameters = jsonencode({
    effect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
      metadata = {
        displayName = "Effect"
        description = "The effect determines what happens when the policy rule is evaluated to match"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          anyOf = [
            {
              anyOf = [
                {
                  field  = "Microsoft.Storage/storageAccounts/allowSharedKeyAccess"
                  exists = "false"
                },
                {
                  field  = "Microsoft.Storage/storageAccounts/allowSharedKeyAccess"
                  equals = ""
                }
              ]
            },
            {
              field  = "Microsoft.Storage/storageAccounts/allowSharedKeyAccess"
              equals = "true"
            }
          ]
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}
