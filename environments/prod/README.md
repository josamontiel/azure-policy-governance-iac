# Production Environment

The Terraform entrypoint for the production management group (`mg-governance-lab-prod`).

`terraform init` and `terraform apply` are run from this directory. State lives remotely in an Azure Blob Storage backend; locking is handled natively through blob leases.

---

## What this composes

```
main.tf
└── module.policy_deny_shared_key_access      → custom policy definition
└── module.initiative_security_baselines      → bundles five policies + initiative parameters
└── module.assignment_security_baselines      → MG-scope assignment + managed identity + role grants
```

Each module lives under `../../modules/`. The composition here passes prod-specific values (workspace ID, allowed locations, effects) into the modules.

---

## Files

| File | Purpose | In git? |
|---|---|---|
| `main.tf` | Module composition | ✅ |
| `providers.tf` | Provider version + backend declaration | ✅ |
| `variables.tf` | Declares sensitive variables expected at runtime | ✅ |
| `backend.hcl` | State backend connection details | ❌ Gitignored |
| `terraform.tfvars` | Sensitive variable values | ❌ Gitignored |

---

## Running locally

Prerequisites: Terraform 1.6+, Azure CLI authenticated, RBAC sufficient to manage policy definitions, set definitions, assignments, and role assignments at the management group scope.

Create the two gitignored files first:

**`backend.hcl`**

```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "<your-state-storage-account>"
container_name       = "tfstate"
key                  = "prod.tfstate"
```

**`terraform.tfvars`**

```hcl
log_analytics_workspace_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace>"
```

Then:

```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Expected steady state: `terraform plan` returns `No changes. Your infrastructure matches the configuration.`

---

## A note on the policy_definition_id casing

The assignment module call in `main.tf` constructs the initiative's `policy_definition_id` as a hand-built string rather than reading it directly from `module.initiative_security_baselines.id`. This works around [AzureRM provider issue #23519](https://github.com/hashicorp/terraform-provider-azurerm/issues/23519): `azurerm_management_group_policy_assignment.policy_definition_id` is treated case-sensitively, and casing differences between Azure's stored value and Terraform's canonical output trigger a forced replacement on every plan.

Reverting to `module.initiative_security_baselines.id` will reintroduce the destroy-and-recreate behaviour. Leave the hand-constructed string in place until the upstream issue is fixed.

---

## Related

* **Repo root:** [../../README.md](../../README.md)
* **Companion narrative repo:** [azure-policy-governance](https://github.com/josamontiel/azure-policy-governance)
