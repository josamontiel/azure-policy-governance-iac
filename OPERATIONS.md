# Operations

How the governance baseline in this repo is changed, reviewed, and operated.

The technical scaffolding lives in the [README](./README.md). This document covers the human side: what gets reviewed, how often, by whom, and what to do when something breaks. If you're picking up this repo from someone else, start here.

---

## Roles and responsibilities

For a solo lab, "the lab operator" wears every hat. The roles are still worth naming because they map to how a real team would split this work:

| Role | Responsible for |
|---|---|
| **Lab operator** | All operational decisions: change approval, exemption owner, incident response, review cadence enforcement |
| **Reviewer** | Reading PR plan output, confirming intent, catching unexpected drift before merge |
| **Approver** | Production environment approval after merge — same person as Reviewer in current setup, but the gate exists deliberately for the two-stage check |

In a real team, the Reviewer and Approver would typically be different people, ensuring no single engineer can both write and deploy a change unsupervised. The pipeline preserves that separation of concerns even when one person performs both — the manual approval gate at deploy time is a deliberate second-look opportunity, not a rubber stamp.

---

## How a change to the governance baseline flows

This is the canonical workflow for any change — a new policy, an updated parameter, an exemption, an effect flip from Audit to Deny. **Never apply through the Portal or via local `terraform apply`.** Everything goes through the pipeline.

Worked example: flipping the public network access policy from Audit to Deny.

1. **Branch** locally:
   ```bash
   git checkout -b feature/<descriptive-name>
   ```

2. **Edit** the relevant Terraform files. For an effect change, the value typically lives in `environments/prod/variables.tf` (default) or in a tfvars file (per-environment override).

3. **Local plan** to preview:
   ```bash
   cd environments/prod
   terraform plan
   ```
   Confirm the diff matches expectations. Stop if anything unexpected shows up — particularly any `forces replacement` markers or destroys.

4. **Format and commit**:
   ```bash
   terraform fmt -recursive
   git add <files>
   git commit -m "feat: <descriptive message>"
   git push -u origin feature/<descriptive-name>
   ```

5. **Open a PR** on GitHub. The plan workflow runs automatically and posts a comment with format/validate/plan results plus the full plan diff.

6. **Review the PR comment.** The plan workflow posts what would happen if applied. Confirm:
   - Format, Validate, and Plan all show ✅
   - The resource changes match what was intended in the commit message
   - No `forces replacement` markers
   - No unexpected drift on resources unrelated to the change

7. **Merge** the PR after the plan looks correct. The apply workflow is automatically triggered on merge to main.

8. **Approve the production environment** when the apply workflow pauses. This is the second gate — last opportunity to cancel before infrastructure changes.

9. **Verify** post-apply. For policy effect changes, this means:
   - Confirm the parameter is set correctly in Azure (`az policy assignment show ... --query parameters.<paramName>`)
   - Test the policy actually behaves as expected (deploy a violating resource and confirm it gets blocked, or for Audit policies, check the compliance dashboard for new flags)

The change is complete when both the apply and the verification confirm intended behaviour.

---

## Review cadence

Three different things get reviewed at three different cadences:

### Weekly: compliance state

Every Monday (or whatever fixed weekday works), spend 5-10 minutes reviewing the compliance dashboard:

1. Portal → Policy → Compliance → scope to `mg-governance-lab-prod`
2. Click into the initiative
3. Note any non-compliant resources

Three outcomes possible from a weekly review:

- **All clean** — log nothing, move on
- **New non-compliant resources flagged** — investigate. Either fix the resource, write an exemption, or adjust the policy. Don't leave findings unaddressed for more than two weeks
- **An audit-mode policy is accumulating findings** — this is signal for an Audit-then-Deny conversation. If the audit is consistently clean, time to flip. If it's consistently flagging, time to fix the underlying resources

### Monthly: exemption review

Every first of the month, list active exemptions and check expiry dates:

```bash
az policy exemption list \
  --scope /providers/Microsoft.Management/managementGroups/mg-governance-lab-prod \
  --query "[].{name:name, expiresOn:properties.expiresOn, displayName:properties.displayName}" \
  -o table
```

For each exemption:

- **Expires within 30 days** — start the renewal conversation. Is the underlying issue fixable now? Is the exemption still justified? Has the scope changed?
- **Expires in 30-90 days** — note for next month
- **Expires beyond 90 days** — no action needed, system is working

### Quarterly: policy and initiative posture

Every three months, broader review:

- Are the right policies in the initiative?
- Have any policies in the initiative been deprecated by Microsoft or upgraded with new versions worth adopting?
- Has the initiative's parameter design held up, or are values being overridden in ways that suggest the design is wrong?
- Are new resource types in use that should be in scope (e.g., if the lab starts using Key Vault, what Key Vault policies should be added)?

Quarterly reviews tend to surface architectural decisions, not configuration tweaks. Document the decision and what changed.

---

## Exemptions

When to write one, how to write one, how to renew.

### When to write an exemption

An exemption is the right answer when:

- **The non-compliance is real and persistent** — a real resource that genuinely doesn't satisfy the policy
- **Fixing the resource isn't possible or isn't desirable** — typically because the configuration is required for legitimate operations, or because fixing would require infrastructure that's out of scope
- **There is a documented technical reason** — an exemption isn't "we'll get to it later"; it's "here's why this configuration is correct for this resource"

An exemption is the *wrong* answer when:

- The resource just hasn't been fixed yet (write a ticket, fix it)
- The policy is wrong (fix the policy)
- The resource shouldn't exist (delete it)

If you find yourself reaching for an exemption to make a dashboard turn green without solving the underlying issue, stop and reconsider.

### How to write an exemption

Live example in this repo: `modules/exemptions/state-backend-public-network/`. The state backend storage account requires public network access for management operations from local machines and GitHub-hosted runners. Closing access would require private endpoints and a self-hosted runner — out of scope for the lab.

The pattern:

- **Module per exemption** under `modules/exemptions/<name>/` containing `main.tf`, `variables.tf`, `outputs.tf`
- **Composed in `environments/prod/main.tf`** with the resource ID, policy assignment ID, and the specific policy reference IDs being exempted
- **Always scope narrowly** — exempt only the policy reference IDs that genuinely don't apply, not the whole assignment. A whole-assignment exemption suppresses every policy's evaluation against the resource, which usually masks more than intended
- **Always time-bound** — `expires_on` is required by the module variable; there is no default. Lab exemptions are typically six months; production should typically be three
- **Document the reason** — the `description` field should name an owner, link to a ticket, and explain why the exemption exists, not just that it does
- **Quarterly review** — the metadata block should set `next_review` to one quarter out, separate from `expires_on`. The review happens before the exemption lapses, not as it lapses

### How to renew an exemption

A month before an exemption expires:

1. Re-read the original justification. Is it still true?
2. Has the underlying issue become fixable in the time since the exemption was written?
3. Has the scope of the exempted resource changed in a way that affects the justification?

If renewal is the right answer, open a PR that updates the `expires_on` date in the relevant module call. The change goes through the same plan/review/apply flow as any other change. The Git history then preserves a record of when each renewal happened and why.

If the exemption isn't renewable — the resource should be fixed instead — fix the resource and remove the exemption module call in the same or a subsequent PR.

---

## Runbook: compliance drop

What to do when the compliance dashboard shows non-compliance you didn't expect.

This actually happened during the project's lifetime — the workspace ID parameter got corrupted in the GitHub Actions secret, the value applied to Azure was a bare GUID instead of the full resource ID, and the DINE remediation engine had been silently failing. The discovery came from a routine `terraform plan` flagging unexpected drift.

The pattern that worked, generalised:

### Step 1: Check the source of truth in Azure

Don't trust Terraform's view alone. Query Azure directly:

```bash
# For a policy assignment's parameters
az policy assignment show \
  --name <assignment-name> \
  --scope <scope> \
  --query parameters

# For an initiative's parameter declarations
az policy set-definition show \
  --name <initiative-name> \
  --management-group <mg-name> \
  --query parameters

# For a list of currently non-compliant resources
az policy state list \
  --filter "complianceState eq 'NonCompliant'" \
  --management-group <mg-name> \
  --query "[].{resource:resourceId, policy:policyDefinitionName}" \
  -o table
```

Compare what Azure thinks the configuration is to what your HCL says it should be. The difference is the drift.

### Step 2: Identify the root cause

Drift on policy resources almost always comes from one of:

- **A change in Azure that bypassed Terraform** — someone clicked through the Portal, a script ran, an automated remediation modified state. Question: who or what changed Azure outside the pipeline?
- **A bug in the pipeline** — most commonly, a corrupted secret or environment variable that caused the workflow to apply a bad value. Question: was the most recent apply workflow's input set correctly?
- **A drift detection improvement in the provider** — Terraform's awareness of certain fields can change between provider versions. Question: did the provider get upgraded recently?

### Step 3: Fix at the source

If the drift is benign (e.g., metadata Azure auto-populates), accept it by re-applying. If the drift is harmful (e.g., a corrupted parameter value), fix the *cause* before re-applying:

- Pipeline secret corruption → update the secret in GitHub Settings before re-running
- Manual Portal change → revert in the Portal *or* update HCL to match the new intent, then re-apply through the pipeline
- Provider behaviour change → update the HCL to express the new expected state, document why

Never apply blindly to make the dashboard green. The compliance check is doing its job by surfacing the drift; the right response is to understand it before resolving it.

### Step 4: Verify the fix

After applying, re-run the same Azure-side queries from Step 1. Compare against expectations. The drift should be gone, and `terraform plan` should return clean. If either still shows differences, the fix is incomplete — return to Step 2.

### Step 5: Document what happened

If the drift was caused by something that could happen again, note it. Worth adding a section to this runbook, or a defensive control to the pipeline, or a guardrail in the relevant module. The corrupted-secret incident, for example, is the reason `LOG_ANALYTICS_WORKSPACE_ID` is now treated with extra scrutiny in compliance reviews.

---

## Things that should never happen

A short list of operations that bypass the pipeline and should never occur in normal operation:

- **`terraform apply` from a laptop against the prod environment.** This was acceptable during the migration phase to recover from incidents, but should not be routine. Every change goes through the PR.
- **Direct edits to policy definitions, set definitions, or assignments via the Portal.** The Portal is read-only for inspection; changes happen in code.
- **Disabling the production environment's required reviewer.** This is the second gate. It exists deliberately. Removing it bypasses the only manual review opportunity at deploy time.
- **Force-pushing to main.** History rewrites are sometimes necessary (the JSON exposure incident in this project's history was one such case), but they're an emergency tool. Routine changes go through the PR cycle.
- **Open-ended exemptions.** Any exemption without an `expires_on` date is operationally invisible — it never resurfaces for review. The module variable enforces this; if you find an exemption without an expiry, that's a defect to fix.

---

## Related

- [Repo README](./README.md) — what the repo contains and how to run locally
- [Companion narrative repo](https://github.com/josamontiel/azure-policy-governance) — phase-by-phase build documentation and screenshots
