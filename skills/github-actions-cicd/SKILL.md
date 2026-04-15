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
>
> - A) `environments/sbx.tfvars`
> - B) `environments/dev.tfvars`
> - C) Other — specify the path

**Q3**

> Include an apply workflow (`terraform-apply.yml`) triggered on merge to `main`?
>
> - A) Yes
> - B) No — plan/validate workflow only for now

**Q4** _(only if Q3 is Yes)_

> What GitHub environment name should gate the apply step?
>
> - A) `production` (default)
> - B) Other — specify

After collecting all answers, confirm your understanding before generating.

## Step 2 — Generate the workflow files

Before writing any YAML, read [`../../standards/templates/github-actions-best-practices.md`](../../standards/templates/github-actions-best-practices.md) in full.

### `terraform-plan.yml`

Generate a complete workflow with these jobs:

| Job        | Needs    | Steps                                                                                                                                              |
| ---------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `validate` | —        | checkout, install tools (`bash "$GITHUB_WORKSPACE/scripts/install-tools.sh"`), `task all` (fmt, validate, lint), tfsec (separate step — see below) |
| `plan`     | validate | checkout, install tools, cache Terraform plugins, init (OIDC + inline backend config), plan, upload artifact                                       |

**Taskfile requirement** — every solution must have a `Taskfile.yml` with an `all` task that runs `fmt`, `validate`, and `lint`. Security (`tfsec`) runs as a separate step in the pipeline so it can be made non-blocking.

**tfsec — non-blocking for non-production:** tfsec always runs, but must not stop the pipeline unless the environment is production. Use `continue-on-error` conditioned on the environment input:

```yaml
- name: tfsec
  run: tfsec .
  continue-on-error: ${{ !contains(fromJSON('["prod","prod","production"]'), inputs.environment) }}
```

**Backend config** — always inline via `-backend-config` flags derived from `environment` and `solution` inputs:

- `resource_group_name=rg-<environment>-platform-terraform-state`
- `storage_account_name=st<environment>platformtfstate`
- `container_name=tfstate`
- `key=<solution>/terraform.tfstate`
- `use_azuread_auth=true`

### `terraform-apply.yml` _(only if Q3 is Yes)_

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

| Secret                  | Value                                          |
| ----------------------- | ---------------------------------------------- |
| `AZURE_CLIENT_ID`       | Managed identity / service principal client ID |
| `AZURE_TENANT_ID`       | Entra ID tenant ID                             |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID                          |

**Azure federated credentials to configure** (one-time, on the managed identity or service principal):

| Subject                                 | Used by                    |
| --------------------------------------- | -------------------------- |
| `repo:<org>/<repo>:pull_request`        | plan and cost jobs on PRs  |
| `repo:<org>/<repo>:ref:refs/heads/main` | apply job on merge to main |

**Security reminder:** Pin all `uses:` entries to full commit SHAs — look them up via the GitHub API, never guess. For each action at tag `vX.Y.Z`:

```
https://api.github.com/repos/<owner>/<repo>/git/ref/tags/vX.Y.Z
```

If the returned `object.type` is `"tag"` (annotated), follow the SHA to `git/tags/<sha>` to get the underlying commit SHA. See [standards/templates/github-actions-best-practices.md](../../standards/templates/github-actions-best-practices.md).

**Reusable workflows:** If generating a reusable workflow (`workflow_call`), the calling job must explicitly grant the permissions the reusable workflow needs (`id-token: write`). See the reusable workflows section in the standards.

---

## Standards

All generated workflows must conform to [`../../standards/templates/github-actions-best-practices.md`](../../standards/templates/github-actions-best-practices.md).
