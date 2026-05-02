# Azure Policy Governance — Infrastructure as Code

Terraform implementation of the governance baseline built and documented in [azure-policy-governance](https://github.com/josamontiel/azure-policy-governance).

This repo is the engineering artifact. The companion repo is the story — screenshots, narrative, decisions. If you've landed here first, that one's worth reading next.

---

## What this repo does

Translates a Portal-built Azure Policy baseline — custom policy definitions, a security initiative, and its management-group-scoped assignment — into version-controlled Terraform. Every change to the governance baseline goes through Git: pull request, review, plan preview, merge, deploy.

This is the modern equivalent of Azure Blueprints (now deprecated). Initiatives bundle the controls; Terraform deploys them; GitHub Actions runs the pipeline; OIDC federated authentication keeps long-lived secrets out of the build environment.

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
│       └── backend.hcl      # Backend config (gitignored)
├── modules/
│   ├── policies/            # One folder per policy definition
│   │   └── deny-shared-key-access/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── initiatives/         # Initiative definitions
│   └── assignments/         # Assignments to scopes
└── .github/
    └── workflows/           # CI/CD pipeline (planned)
```

Modules are reusable building blocks. Environments compose them with environment-specific values. Each environment has its own remote state file — `prod.tfstate` lives in the backend storage account, separately from any future `dev` or `staging` state.

---

## Getting started locally

Prerequisites: Terraform 1.6+, Azure CLI, an account with `Resource Policy Contributor` (or higher) at the management group scope.

```bash
# Authenticate to Azure
az login

# Initialise Terraform with the remote backend
cd environments/prod
terraform init -backend-config=backend.hcl

# See what Terraform would do
terraform plan
```

`backend.hcl` is gitignored. To run locally, create one with the values for your own state backend:

```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "<your-state-storage-account>"
container_name       = "tfstate"
key                  = "prod.tfstate"
```

---

## State management

State lives in a dedicated Azure Blob Storage account in `rg-terraform-state` — deliberately separate from the resource group containing the governance lab itself. This keeps state lifecycle independent of the resources it manages.

Versioning is enabled on the storage account. State locking is handled natively by the `azurerm` backend through blob leases — no separate lock table required.

The state file contains a complete record of every Terraform-managed resource and the parameter values used to create it. Read access on the state backend is therefore equivalent to read access on every secret that has flowed through a Terraform run. Scope state backend RBAC accordingly.

---

## Status

| Component | Status |
|---|---|
| Repo bootstrap and remote state backend | ✅ |
| Custom policy: `deny-shared-key-access` | ✅ Imported under Terraform management |
| Built-in policies (tags, allowed locations, diagnostics, public network access) | 🚧 To be referenced from initiative module |
| Initiative: `governance-lab-security-baselines` | 🚧 In progress |
| MG-scope assignment with managed identity | 📋 Planned |
| GitHub Actions pipeline (OIDC, plan preview, deploy on merge) | 📋 Planned |

---

## Notes from translating Portal-built policy into code

A few things surfaced during the import that wouldn't have been visible from the Portal alone, and which justify the IaC effort on their own:

- The custom policy's *display name* described one control while its *rule logic* implemented another. The Portal showed both fields on different tabs, which made the mismatch easy to miss. A `terraform plan` against the imported state surfaced it within minutes.
- A duplicate policy definition existed at subscription scope, orphaned from any assignment. Easy to overlook in the Portal's flat list view; obvious once both definitions appeared in `az policy definition list`.
- Both findings were captured in a single `terraform state mv` and a metadata rename — no rule logic changed, no resource recreated, no compliance evaluation disrupted.

This is the "why we do Policy as Code" argument made concrete. The Portal lets you build governance; Git lets you maintain it.

---

## Related

- **[azure-policy-governance](https://github.com/josamontiel/azure-policy-governance)** — the documented narrative, screenshots, and phase-by-phase build of the underlying lab.
