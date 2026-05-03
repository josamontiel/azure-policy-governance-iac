# Azure Policy Governance — Infrastructure as Code

Terraform implementation of the governance baseline built and documented in [azure-policy-governance](https://github.com/josamontiel/azure-policy-governance).

This repo is the engineering artifact. The companion repo is the story — screenshots, narrative, decisions. If you've landed here first, that one's worth reading next.

---

## What this repo does

Translates a Portal-built Azure Policy baseline — a custom policy definition, an initiative bundling five policies, and a management-group-scoped assignment with managed identity remediation — into version-controlled Terraform deployed through a GitHub Actions pipeline.

Pull requests run `terraform plan` automatically and post the diff as a PR comment. Merges to `main` trigger an environment-gated `terraform apply`. Authentication uses OIDC federated credentials — no long-lived secrets stored anywhere.

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
    └── workflows/
        ├── terraform-plan.yml   # Plan-on-PR with diff comment
        └── terraform-apply.yml  # Apply-on-merge with environment gate
```

Modules are reusable building blocks. Environments compose them with environment-specific values. Each environment has its own remote state file — `prod.tfstate` lives in the backend storage account, separately from any future `dev` or `staging` state.

---

## CI/CD pipeline

Two workflows, both authenticated via OIDC federated credentials against an Entra ID app registration scoped to this repo:

**`terraform-plan.yml`** — runs on pull requests. Executes `terraform fmt -check`, `validate`, and `plan`. Posts a comment on the PR showing the format/validate/plan results and the full plan output. Reviewers see exactly what would change before approving.

**`terraform-apply.yml`** — runs on push to `main`. Executes `plan` then `apply -auto-approve`. Gated by a GitHub Environment with required reviewer — the workflow pauses until manual approval before applying.

Authentication uses three federated credentials on the app registration, one per workflow context (pull request, main branch push, and the `production` environment). State backend uses AAD authentication via `use_azuread_auth=true`, so the workflow's identity reads and writes state directly with no access-key dependency.

---

## Getting started locally

Prerequisites: Terraform 1.6+, Azure CLI authenticated, RBAC sufficient to manage policy definitions, set definitions, assignments, and role assignments at the management group scope, plus Storage Blob Data Contributor on the state backend storage account.

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

Then:

```bash
az login
cd environments/prod
terraform init -backend-config=backend.hcl
terraform plan
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

All five resources under Terraform management, all aligned between HCL and Azure (`terraform plan` returns no changes), all deployable through the pipeline.

---

## State management

State lives in a dedicated Azure Blob Storage account in `rg-terraform-state` — deliberately separate from the resource group containing the governance lab itself. This keeps state lifecycle independent of the resources it manages.

Versioning is enabled on the storage account. State locking is handled natively by the `azurerm` backend through blob leases — no separate lock table required. State access uses AAD authentication (`use_azuread_auth=true`) rather than storage account keys, so RBAC governs who can read or modify state.

The state file contains a complete record of every Terraform-managed resource and the parameter values used to create it. Read access on the state backend is therefore equivalent to read access on every value that has flowed through a Terraform run, including subscription identifiers, resource paths, and any sensitive inputs. Scope state backend RBAC accordingly.

---

## Status

| Component | Status |
|---|---|
| Repo bootstrap and remote state backend | ✅ |
| Custom policy: `deny-shared-key-access` | ✅ |
| Initiative: `governance-lab-security-baselines`, parameterised | ✅ |
| MG-scope assignment, managed identity, role grants | ✅ |
| GitHub Actions pipeline (OIDC, plan-on-PR, apply-on-merge with environment gate) | ✅ |

---

## Notes from translating Portal-built governance into code

A few things surfaced during the migration that wouldn't have been visible from the Portal alone, and which justify the IaC effort on their own:

- The custom policy's *display name* described one control while its *rule logic* implemented another. The Portal showed both fields on different tabs, which made the mismatch easy to miss. A `terraform plan` against the imported state surfaced it within minutes.
- A duplicate policy definition existed at subscription scope, orphaned from any assignment. Easy to overlook in the Portal's flat list view; obvious once both definitions appeared in `az policy definition list`.
- Three redundant policy assignments existed at the same management group scope, evaluating the same controls the initiative already covered. The compliance dashboard had been double- and triple-counting non-compliance findings. Cleanup was four deletions and a recalculated baseline.
- The initiative had no exposed parameters — every value was hardcoded directly into each policy reference, making the baseline non-reusable across environments. The translation introduced six properly-scoped parameters with defaults, which the assignment overrides explicitly.
- The AzureRM provider's `azurerm_management_group_policy_assignment` resource has a known case-sensitivity bug ([issue #23519](https://github.com/hashicorp/terraform-provider-azurerm/issues/23519)) that treats casing differences in `policy_definition_id` as a forced replacement. Worked around by constructing the ID string with the exact mixed casing Azure had stored.
- Pipeline authentication required three federated credentials on the Entra ID app registration — one per workflow context (pull request, main branch push, and the `production` environment). GitHub's OIDC subject claim format varies based on whether the workflow runs in a GitHub Environment.
- Backend authentication needed `use_azuread_auth=true` set both in `providers.tf` and as a `-backend-config` flag on `terraform init` to prevent fallback to access-key auth, which would have required `Microsoft.Storage/storageAccounts/listKeys` (a control-plane permission distinct from the Storage Blob Data Contributor role granted to the workflow identity).

This is the "why we do Policy as Code" argument made concrete. The Portal lets you build governance. Git lets you maintain it.

---

## Related

- **[azure-policy-governance](https://github.com/josamontiel/azure-policy-governance)** — the documented narrative, screenshots, and phase-by-phase build of the underlying lab.
