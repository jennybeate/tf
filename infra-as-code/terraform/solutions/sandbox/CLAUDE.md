# Sandbox Terraform solution

**Environment:** `sbx` — non-production. Purge protection is disabled on Key Vault.

**State:** `sandbox/terraform.tfstate` in storage account `stsbxplatformtfstate`, container `tfstate`

## Module versions

| Resource | Module | Version |
|----------|--------|---------|
| AKS cluster | AVM `azure/aks/azurerm` | v0.5.3 |
| Key Vault | AVM `azure/keyvault/azurerm` | v0.10.2 |
| DNS Zone | AVM `azure/dnszone/azurerm` | v0.2.1 |
| Storage account | local `../../modules/storage-account` | — |

## Deployment

Changes deploy via PR → pipeline, not `task apply` directly.

1. Edit `environments/sbx.tfvars`
2. Open a PR — `terraform-plan-sandbox.yml` runs validate and plan automatically
3. Merge to `main` — `terraform-apply-sandbox.yml` applies

`task apply` works locally for development but state is shared — coordinate with the team before running it outside the pipeline.

## OIDC subject claims

The pipeline authenticates to Azure using OIDC. The App Registration must have federated credentials for:
- Entity type `Pull request` — used by the plan workflow
- Entity type `Branch`, branch `main` — used by the apply workflow

See `.github/docs/oidc.md` for details.

## Teardown

Trigger `workflow_dispatch` on `terraform-apply-sandbox.yml` if a destroy target is configured, or run `task destroy` locally. After destroy, purge the soft-deleted Key Vault with `task purge` so the name is free for re-deployment.
