---
name: github-actions-cicd
description: "Generate GitHub Actions CI/CD workflows for Terraform modules on Azure. Scaffolds terraform-plan.yml (PR validation) and optionally terraform-apply.yml (apply on merge with environment protection)."
argument-hint: "Name or path of the Terraform module to create a pipeline for, or just say 'go' to start"
---

# Terraform CI/CD Pipeline Generator

Guide the user through generating GitHub Actions workflows for their Terraform module.

## Step 1 — Gather requirements

Ask the following questions **one at a time**. Wait for each answer before asking the next.

**Q1**
> What is the relative path to the Terraform module?
> (e.g. `modules/storage-account`)

**Q2**
> Which environment `.tfvars` file should the plan job use?
> - A) `environments/sbx.tfvars`
> - B) `environments/dev.tfvars`
> - C) Other — specify the path

**Q3**
> Include an apply workflow (`terraform-apply.yml`) triggered on merge to `main`?
> - A) Yes
> - B) No — plan/validate workflow only for now

**Q4** *(only if Q3 is Yes)*
> What GitHub environment name should gate the apply step?
> - A) `production` (default)
> - B) Other — specify

After collecting all answers, confirm your understanding before generating.

## Step 2 — Generate the workflow files

Before writing any YAML, read [`../../standards/templates/github-actions-best-practices.md`](../../standards/templates/github-actions-best-practices.md) in full.

### `terraform-plan.yml`

Generate a complete workflow with these jobs:

| Job | Needs | Steps |
|-----|-------|-------|
| `validate` | — | fmt check, setup-tflint, tflint init + cache, tflint, init -backend=false, validate, tfsec |
| `plan` | validate | init (OIDC + inline backend config), plan → `plan.txt`, read output, find+create-or-update PR comment, upload artifact |

**Backend config** — always inline via `-backend-config` flags (not a committed file):
- Secrets: `TF_BACKEND_RESOURCE_GROUP`, `TF_BACKEND_STORAGE_ACCOUNT`
- Hardcoded: `container_name=tfstate`, `use_azuread_auth=true`
- Key: `<module-folder-name>/terraform.tfstate`

**Plan comment** — use `peter-evans/find-comment` + `peter-evans/create-or-update-comment` with `<!-- tf-plan-comment -->` marker.

**Multiline plan output** — capture to file and use the heredoc pattern:
```yaml
- name: Read plan output
  id: plan-output
  run: |
    {
      echo 'CONTENT<<PLAN_EOF'
      cat plan.txt
      echo 'PLAN_EOF'
    } >> "$GITHUB_OUTPUT"
```

### `terraform-apply.yml` *(only if Q3 is Yes)*

Single `apply` job:
- Trigger: `push` to `main`, `paths:` scoped to the module, plus `workflow_dispatch`
- Environment: the name from Q4 (triggers required-reviewer gate)
- Steps: checkout, setup-terraform, init (same inline backend config), apply `-var-file=<tfvars> -auto-approve`
- OIDC env vars: same `ARM_*` pattern as plan workflow

Produce all files in full — do not truncate.

## Step 3 — Print the prerequisites checklist

After generating the files, print this for the user:

---

**GitHub secrets to add** (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Managed identity / service principal client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `TF_BACKEND_RESOURCE_GROUP` | Resource group of the Terraform state storage account |
| `TF_BACKEND_STORAGE_ACCOUNT` | Name of the Terraform state storage account |
**Azure federated credentials to configure** (one-time, on the managed identity or service principal):

| Subject | Used by |
|---------|---------|
| `repo:<org>/<repo>:pull_request` | plan and cost jobs on PRs |
| `repo:<org>/<repo>:ref:refs/heads/main` | apply job on merge to main |

**Security reminder:** Pin all `uses:` entries to full commit SHAs before merging to `main`. See [standards/templates/github-actions-best-practices.md](../../standards/templates/github-actions-best-practices.md).

---

## Standards

All generated workflows must conform to [`../../standards/templates/github-actions-best-practices.md`](../../standards/templates/github-actions-best-practices.md).
