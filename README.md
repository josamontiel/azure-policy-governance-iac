# Azure Policy Governance — Infrastructure as Code

Terraform implementation of the governance baseline built and documented in [azure-policy-governance](https://github.com/josamontiel/azure-policy-governance).

This repo is the engineering artifact. The companion repo is the story — screenshots, narrative, decisions. If you've landed here first, that one's worth reading next.

---

## What this repo does

Translates a Portal-built Azure Policy baseline — a custom policy definition, an initiative bundling five policies, and a management-group-scoped assignment with managed identity remediation — into version-controlled Terraform. Every change to the governance baseline now goes through git: pull request, review, plan preview, merge, deploy.

This is the modern equivalent of Azure Blueprints (now deprecated). Initiatives bundle the controls; Terraform deploys them; the assignment binds the initiative to a scope with parameters; managed identities handle remediation; and everything is reviewable in code before it touches Azure.

---

## Why Terraform rather than Bicep

Two reasons:

1. **Transferable patterns.** HCL and the module-and-environment structure work the same in AWS, GCP, and on-prem. Bicep is Azure-only.
2. **Explicit state.** Terraform forces you to think about where state lives, who can read it, and how drift gets detected. That mental model is central to production IaC and worth practising in a lab.

Either tool would work. Terraform is the broader CV signal.

---

## Repo structure

```
.
├── environments/
│   └── prod/                # Entrypoint — `terraform init` and `apply` run from here
│       ├── main.tf          # Composes modules with env-specific values
│       ├── providers.tf     # Provider versions, backend declaration
│       ├── variables.tf     # Sensitive inputs declared here
│       ├── backend.hcl      # Backend config (gitignored)
│       └── terraform.tfvars # Sensitive values (gitignored)
├── modules/
│   ├── policies/
│   │   └── deny-shared-key-access/
│   ├── initiatives/
│   │   └── security-baselines/
│   └── assignments/
│       └── security-baselines/
└── .github/
    └── workflows/           # CI/CD pipeline (planned)
```

Modules are reusable building blocks. Environments compose them with environment-specific values. Each environment has its own remote state file — `prod.tfstate` lives in the backend storage account, separately from any future `dev` or `staging` state.

---

## Getting started locally

Prerequisites: Terraform 1.6+, Azure CLI, an account with `Resource Policy Contributor` (or higher) at the management group scope, plus permissions to create role assignments.

```bash
# Authenticate to Azure
az login

# Initialise Terraform with the remote backend
cd environments/prod
terraform init -backend-config=backend.hcl

# See what Terraform would do
terraform plan
```

Two gitignored files need creating before the first run:

**`environments/prod/backend.hcl`** — points Terraform at the remote state backend:

```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "<your-state-storage-account>"
container_name       = "tfstate"
key                  = "prod.tfstate"
```

**`environments/prod/terraform.tfvars`** — provides sensitive variable values:

```hcl
log_analytics_workspace_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace>"
```

---

## What's under management

| Resource | Type | Status |
|---|---|---|
| `deny-shared-key-access` policy | Custom policy definition (MG-scoped) | ✅ Imported |
| `Governance Lab Security Baselines` initiative | Custom policy set definition (MG-scoped) | ✅ Imported, parameterised |
| Initiative assignment | MG-scoped assignment with managed identity | ✅ Imported |
| Log Analytics Contributor role assignment | Role grant on managed identity | ✅ Imported |
| Monitoring Contributor role assignment | Role grant on managed identity | ✅ Imported |

Five resources, all under Terraform management, all aligned between HCL and Azure (`terraform plan` returns no changes).

---

## State management

State lives in a dedicated Azure Blob Storage account in `rg-terraform-state` — deliberately separate from the resource group containing the governance lab itself. This keeps state lifecycle independent of the resources it manages.

Versioning is enabled on the storage account. State locking is handled natively by the `azurerm` backend through blob leases — no separate lock table required.

The state file contains a complete record of every Terraform-managed resource and the parameter values used to create it. Read access on the state backend is therefore equivalent to read access on every value that has flowed through a Terraform run, including subscription identifiers, resource paths, and any sensitive inputs. Scope state backend RBAC accordingly.

---

## Status

| Component | Status |
|---|---|
| Repo bootstrap and remote state backend | ✅ |
| Custom policy: `deny-shared-key-access` | ✅ |
| Initiative: `governance-lab-security-baselines`, parameterised | ✅ |
| MG-scope assignment, managed identity, role grants | ✅ |
| GitHub Actions pipeline (OIDC, plan-on-PR, deploy-on-merge) | 📋 Planned |

---

## Notes from translating Portal-built governance into code

A few things surfaced during the migration that wouldn't have been visible from the Portal alone, and which justify the IaC effort on their own:

- The custom policy's *display name* described one control while its *rule logic* implemented another. The Portal showed both fields on different tabs, which made the mismatch easy to miss. A `terraform plan` against the imported state surfaced it within minutes.
- A duplicate policy definition existed at subscription scope, orphaned from any assignment. Easy to overlook in the Portal's flat list view; obvious once both definitions appeared in `az policy definition list`.
- Three redundant policy assignments existed at the same management group scope, evaluating the same controls the initiative already covered. The compliance dashboard had been double- and triple-counting non-compliance findings. Cleanup was four deletions and a recalculated baseline.
- The initiative had no exposed parameters — every value was hardcoded directly into each policy reference, making the baseline non-reusable across environments. The translation introduced six properly-scoped parameters with defaults, which the assignment overrides explicitly.
- The AzureRM provider's `azurerm_management_group_policy_assignment` resource has a known case-sensitivity bug ([issue #23519](https://github.com/hashicorp/terraform-provider-azurerm/issues/23519)) that treats casing differences in `policy_definition_id` as a forced replacement. Worked around by constructing the ID string with the exact mixed casing Azure had stored.

This is the "why we do Policy as Code" argument made concrete. The Portal lets you build governance. Git lets you maintain it.

---

## Related

- **[azure-policy-governance](https://github.com/josamontiel/azure-policy-governance)** — the documented narrative, screenshots, and phase-by-phase build of the underlying lab.
