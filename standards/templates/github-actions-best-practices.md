---
applyTo: '.github/workflows/*.yml,.github/workflows/*.yaml'
description: 'Standards reference for GitHub Actions workflows in Terraform repositories. Covers workflow structure, OIDC authentication, secret management, caching, plan artifacts, and PR comments. For generating workflows, use the tf-cicd skill.'
---

# GitHub Actions — Terraform Workflow Standards

Standards reference for GitHub Actions workflows in this repository. For scaffolding new workflows, use the `tf-cicd` skill.

## Workflow structure

### Triggers and concurrency

```yaml
on:
  pull_request:
    branches: [main]
    paths: ["modules/**"]   # scope to relevant directories
  workflow_dispatch:         # always include for manual runs

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # cancel stale runs on the same PR
```

Use `pull_request` for plan/validate workflows. Use `push` on `main` (or `workflow_dispatch`) for apply workflows.

### Permissions

Set `permissions: {}` at the workflow level (deny-all by default). Grant only what each job needs:

| Job type | Minimum permissions |
|----------|-------------------|
| Static validation (fmt, lint, tfsec) | `contents: read` |
| Plan (OIDC + Azure) | `contents: read`, `id-token: write` |
| PR comments | `pull-requests: write` |

### Action versioning

Pin all `uses:` to full commit SHAs — never tags. Tags are mutable; a compromised tag can silently execute arbitrary code in your pipeline (supply chain attack). Add the version as a comment:

```yaml
# ✅ GOOD — immutable SHA with readable version comment
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

# ❌ BAD — mutable tag, vulnerable to tag-move attacks
uses: actions/checkout@v4
```

## Azure authentication (OIDC)

Use OIDC federated credentials — no long-lived secrets. Pass credentials at the job or step level via environment variables:

```yaml
env:
  ARM_CLIENT_ID:       ${{ secrets.AZURE_CLIENT_ID }}
  ARM_TENANT_ID:       ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_USE_OIDC:        "true"
```

Configure federated credential subjects on the managed identity (one-time):
- PRs: `repo:<org>/<repo>:pull_request`
- Main branch: `repo:<org>/<repo>:ref:refs/heads/main`

## Secret management

- Store all credentials as GitHub repo or environment secrets — never hardcode values in workflow files.
- Pass secrets only to jobs that need them (`env:` at job or step level, not at workflow level).
- Backend config values (resource group name, storage account name) are not secrets — store as GitHub Actions **variables** (`vars.NAME`) and reference via `${{ vars.TF_BACKEND_RESOURCE_GROUP }}` / `${{ vars.TF_BACKEND_STORAGE_ACCOUNT }}`. Using `secrets.NAME` for a variable silently returns an empty string.

## Terraform backend config

Pass backend values inline via `-backend-config` flags — avoids committing a `backend.hcl` file with environment-specific values:

```yaml
- name: Terraform init
  run: |
    terraform init \
      -backend-config="resource_group_name=${{ secrets.TF_BACKEND_RESOURCE_GROUP }}" \
      -backend-config="storage_account_name=${{ secrets.TF_BACKEND_STORAGE_ACCOUNT }}" \
      -backend-config="container_name=tfstate" \
      -backend-config="key=<module-name>/terraform.tfstate" \
      -backend-config="use_azuread_auth=true"
```

## Caching

Cache Terraform providers and tflint plugins to avoid redundant downloads on every run.

**Terraform provider cache** — set `TF_PLUGIN_CACHE_DIR` on the init step so Terraform writes providers to the shared cache directory rather than `.terraform/`:

```yaml
- name: Configure Terraform plugin cache dir
  run: mkdir -p ~/.terraform.d/plugin-cache

- name: Cache Terraform plugins
  uses: actions/cache@...
  with:
    path: ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: ${{ runner.os }}-terraform-

- name: Terraform init
  run: terraform init ...
  env:
    TF_PLUGIN_CACHE_DIR: ~/.terraform.d/plugin-cache
```

The `**/.terraform.lock.hcl` glob covers lock files in any module subdirectory. The `restore-keys` fallback allows a partial cache hit when only some providers changed.

**tflint plugin cache:**

```yaml
- name: Cache tflint plugins
  uses: actions/cache@...
  with:
    path: ~/.tflint.d/plugins
    key: tflint-${{ runner.os }}-${{ hashFiles('.tflint.hcl') }}
```

## Plan artifacts

Always upload the binary plan file as a workflow artifact for audit and potential reuse in an apply workflow:

```yaml
- uses: actions/upload-artifact@...
  with:
    name: tfplan-${{ github.run_id }}
    path: modules/<name>/tfplan
    retention-days: 7
```

## PR comments

Post plan output as an updating PR comment — use `peter-evans/find-comment` + `peter-evans/create-or-update-comment` with a unique HTML marker so the same comment is updated on re-push, not duplicated:

```yaml
# Marker in the plan comment body — used to find and update the existing comment:
<!-- tf-plan-comment -->
```

## tfsec

`tfsec` is not pre-installed on `ubuntu-latest`. Always use the action — never `run: tfsec .`:

```yaml
- name: tfsec
  uses: aquasecurity/tfsec-action@<sha> # v1.0.3
  with:
    working_directory: <path>   # relative to repo root — defaults.run.working-directory does NOT apply to uses: steps
```

## Job structure — plan workflow

Standard 2-job pattern for PR validation:

```
validate ──► plan ──► post plan comment to PR
```

- **validate**: fmt check, tflint, `terraform validate`, tfsec — no Azure credentials needed
- **plan**: OIDC init + plan, artifact upload, PR plan comment — needs `id-token: write`

`plan` runs only after `validate` passes.

## Reusable workflows (`workflow_call`)

A reusable workflow cannot use permissions beyond what the calling job explicitly grants. The calling job must declare the permissions the reusable workflow's jobs need:

```yaml
# caller workflow
jobs:
  plan:
    permissions:
      contents: read
      id-token: write        # required if reusable workflow uses OIDC
      pull-requests: write   # required if reusable workflow posts PR comments
    uses: ./.github/workflows/_terraform-plan.yml
    ...
```

Without this, GitHub blocks the run with: *"The nested job is requesting '...write' but is only allowed 'none'"*.

## State locking

Azure Storage backends lock state automatically via blob leases. Two CI concerns:

- **Parallel PR runs on the same state file** — two plan jobs starting at the same time will race for the lease. Add `-lock-timeout=5m` so a job waits for the lease to clear rather than failing immediately.
- **Never pass `-lock=false`** — disabling the lock risks state corruption. If a lock is genuinely stuck, use `terraform force-unlock <lock-id>` locally as a deliberate break-glass action, not as routine CI practice.

```yaml
- name: Terraform plan
  run: |
    terraform plan \
      -var-file environments/sbx.tfvars \
      -lock-timeout=5m \
      -out=tfplan \
      -no-color 2>&1 | tee plan.txt
```

Use `-lock-timeout=5m` on plan and `-lock-timeout=10m` on apply — apply may need to wait longer if the plan lease has not fully cleared.

## Apply workflow

For applying on merge to `main`:

- Use a GitHub `environment` with required reviewers on the apply job — prevents unreviewed applies.
- Set `if: github.ref == 'refs/heads/main'` on the apply job.
- Download the plan artifact from the plan workflow where possible (ensures what was reviewed is what gets applied).

```yaml
apply:
  environment: production   # triggers required-reviewer gate
  needs: plan
  if: github.ref == 'refs/heads/main'
```

## Review checklist

- [ ] `permissions: {}` at workflow level; jobs have minimal per-job grants
- [ ] All `uses:` pinned to full commit SHAs with version comment (look it up, don't guess the SHA)
- [ ] Concurrency group cancels stale runs
- [ ] OIDC used for Azure authentication — `ARM_USE_OIDC: "true"`, no long-lived secrets
- [ ] `ARM_*` env vars scoped to the jobs that run Terraform
- [ ] `paths:` filter scopes PR triggers to relevant module directories
- [ ] tflint plugins cached on `.tflint.hcl` hash
- [ ] Plan binary uploaded as artifact with `retention-days` set
- [ ] Plan comment uses find + create-or-update pattern (no duplicate comments)
- [ ] Apply workflow uses GitHub environment with required reviewers
- [ ] `-lock-timeout=5m` (or longer) on plan and apply commands — never `-lock=false`
- [ ] `timeout-minutes` set on Terraform init/plan/apply steps
