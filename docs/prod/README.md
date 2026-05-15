# Production environment setup

> This guide is a stub. Production infrastructure does not exist yet. Expand this file as the production environment is built out.

---

## Differences from sandbox

| Concern | Sandbox | Production |
|---------|---------|------------|
| Approval gates | None — merge triggers apply | Required manual approval before apply |
| Purge protection | Disabled | Enabled — Key Vault cannot be purged |
| Let's Encrypt | Staging (untrusted certificates) | Production (browser-trusted certificates) |
| Replica count | 1 | 3+ |
| OIDC subject claim | Branch: `main` | Branch: `main` (separate App Registration, separate subscription) |
| Terraform state | `stsbxplatformtfstate` / `sandbox/` | Separate storage account in prod subscription |

---

## One-time platform admin setup

Follow the same steps as sandbox ([`docs/sandbox/README.md`](../sandbox/README.md)) with these differences:

- Create a **separate App Registration** scoped to the production subscription.
- Grant **Owner** on the production subscription, not sandbox.
- Add a separate set of GitHub Actions secrets scoped to production (or use environment-level secrets in a `production` environment with required reviewers).
- Enable approval gates under **Settings → Environments → production → Required reviewers** before wiring any apply workflow to it.

---

## Approval gate

All production applies must wait for a reviewer to approve the plan before proceeding. Configure this under **Settings → Environments → production**:
- Required reviewers: platform team leads
- Wait timer: 0 (immediate review, not timed)

The apply workflow reads the plan artifact from the PR and applies it only after approval. No plan is re-generated at apply time.

---

## Deploy infrastructure

Same flow as sandbox. Edit the production `.tfvars` file, open a PR, merge after pipeline approval.

Add a production environment file at `infra-as-code/terraform/solutions/<solution>/environments/prod.tfvars` when the solution is ready.

---

## Key Vault purge protection

Purge protection is enabled in production. If a Key Vault is destroyed, the name is reserved for 90 days and cannot be reused. Plan Key Vault names carefully — renaming requires a new name or waiting out the retention period.

---

## Next steps for this guide

- [ ] Define production subscription ID and resource group naming
- [ ] Document approval gate workflow configuration
- [ ] Add production `.tfvars` example values
- [ ] Document prod-specific security hardening (KMS encryption, private cluster, API server IP restrictions)
- [ ] Document rollback procedure
