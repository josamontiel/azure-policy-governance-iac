# Azure Policy Governance — Infrastructure as Code

Terraform implementation of the governance baseline built and documented at
[azure-policy-governance](https://github.com/josamontiel/azure-policy-governance).

This repo translates portal-built policies, initiatives, and assignments into
versioned, reviewable, pipeline-deployable Terraform — the modern equivalent of
Azure Blueprints.

## Why Terraform

Built with Terraform rather than Bicep for two reasons: it demonstrates
governance patterns that transfer across clouds, and it requires explicit
handling of state — a concept that's central to production IaC and worth
practising in a lab.

## Status

🚧 Bootstrap and repo structure complete. Module translation in progress.
