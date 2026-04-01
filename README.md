# IaC Training — Getting Started with Terraform on Azure

This repo is the starting point for Nimtech infrastructure consultants learning Infrastructure as Code with Terraform. It gives you a working sandbox environment, a CI/CD pipeline, team coding standards, and AI-assisted tooling — everything you need to go from zero to deploying real Azure resources.

---

## What's in here

```
.
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml     # Runs on every PR — fmt, lint, tfsec, plan
│   │   └── terraform-apply.yml    # Runs on merge to main — applies deployments
│   └── PULL_REQUEST_TEMPLATE.md   # PR checklist
├── .tflint.hcl                    # tflint config — azurerm ruleset
├── bootstrap/
│   └── main.bicep                 # Platform admin: create Terraform state backend (one-time)
├── backend.hcl.example            # Copy to backend.hcl — points to bootstrapped state storage
├── modules/                       # Reusable Terraform modules
│   └── storage-account/
│       ├── main.tf, variables.tf, outputs.tf, etc.
│       ├── environments/
│       │   └── sbx.tfvars         # Environment-specific variables
│       └── tests/
│           └── storage_account.tftest.hcl
├── skills/                        # AI-assisted development
│   ├── tf-architect/              # Skill: scaffold Terraform modules
│   ├── tf-code-reviewer/          # Skill: review .tf files against standards
│   ├── repo-naming-checker/       # Skill: validate resource naming
│   └── code-reviewer/             # Skill: review PowerShell/Bicep/pipelines
├── standards/
│   └── templates/
│       ├── terraform-authoring-guide.md     # Module authoring standards
│       ├── terraform-review.rules.md        # Code review rules
│       ├── terraform-standards.md           # Team conventions
│       ├── naming-conventions.md            # Azure naming rules
│       ├── code-review.rules.md             # Severity definitions
│       └── code-review.output.md            # Review output format
├── .gitignore
├── CLAUDE.md                      # Context for Claude Code — loaded automatically
└── README.md
```

---

## Step 1 — Prerequisites

Install the following tools on your machine:

| Tool | Version | Install |
|------|---------|---------|
| Terraform | `~> 1.9` | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | latest | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| tflint | latest | [github.com/terraform-linters/tflint](https://github.com/terraform-linters/tflint) |
| tfsec | latest | [github.com/aquasecurity/tfsec](https://github.com/aquasecurity/tfsec) |

After installing tflint, run `tflint --init` in the repo root to install the azurerm ruleset.

**Optional but recommended:**
- [Claude Code](https://claude.ai/code) — AI coding assistant with Terraform plugins pre-configured in `CLAUDE.md`
- [GitHub Copilot](https://github.com/features/copilot) — skills in `skills/` are auto-discovered in VS Code agent mode

---

## Step 2 — Bootstrap: create the Terraform state backend

> **Platform admin step — run once per subscription before deploying any infrastructure.**

Terraform stores state in an Azure Storage Account. This storage account must be created before `terraform init` can reference it. Use the Bicep bootstrap template to provision it.

### Prerequisites

- Azure CLI installed: `az login` and set your subscription
- Bicep CLI: `az bicep install`
- An Azure AD App Registration with an Object ID (see Step 3 for federated identity setup)

### Deploy the state backend

Get your app registration Object ID:
```bash
az ad sp show --id <AZURE_CLIENT_ID> --query id -o tsv
```

Deploy the bootstrap:
```bash
az deployment sub create \
  --location norwayeast \
  --template-file bootstrap/main.bicep \
  --parameters deploymentIdentityObjectId="<object-id-from-above>"
```

This creates:
- Resource Group: `rg-sbx-platform-terraform-state`
- Storage Account: `stsbxplatformtfstate`
- Container: `tfstate`
- RBAC: `Storage Blob Data Owner` for your app registration

This deployment is **one-time and idempotent** — safe to re-run. The values match `backend.hcl.example`.

> ⚠️ **AVM module note:** Uses Azure Verified Module `avm/res/storage/storage-account:0.32.0`. This version is pre-1.0.0 but approved for production use by the AVM team.

---

## Step 3 — One-time GitHub setup

Before the pipeline works, a platform admin needs to set this up once per repo.

### Azure OIDC (federated identity — no secrets stored)

1. Create an **App Registration** in Azure AD.
2. Under **Certificates & secrets → Federated credentials**, add two credentials:
   - Entity type: `Branch`, branch name: `main` (used by the apply pipeline)
   - Entity type: `Pull request` (used by the plan pipeline)
3. Grant the app **Contributor** on the sandbox subscription (or narrower scope if preferred).

### GitHub secrets (`Settings → Secrets and variables → Actions → Secrets`)

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

### GitHub variables (`Settings → Secrets and variables → Actions → Variables`)

| Variable | Example value |
|----------|---------------|
| `TF_STATE_RESOURCE_GROUP` | `rg-sbx-platform-terraform-state` |
| `TF_STATE_STORAGE_ACCOUNT` | `stsbxplatformtfstate` |

### GitHub environment (approval gate)

1. Go to **Settings → Environments → New environment**, name it `sandbox`.
2. Add **Required reviewers** — applies will wait for approval before running.

---

## Step 4 — Configure local backend and deploy modules

Once bootstrap is deployed, configure Terraform to use the remote state backend:

```bash
# Copy the backend template
cp backend.hcl.example backend.hcl

# Edit backend.hcl if needed
# (values should match bootstrap deployment: resource group, storage account, container, key)
```

`backend.hcl` is gitignored — never commit it.

### Validate a module

Modules include a `Justfile` with all checks. To validate and test a module:

```bash
cd modules/storage-account
just        # Runs: fmt → validate → lint → security → test
```

All checks must pass before code review.

### Deploy a module

To use a module in your infrastructure, create a root-level Terraform config (e.g., `sandbox/main.tf`):

```hcl
module "storage_account" {
  source = "../modules/storage-account"
  
  cost_center      = "cc-1234"
  environment      = "sbx"
  location         = "norwayeast"
  owner            = "platform-team"
  replication_type = "LRS"
  solution         = "my-solution"
}
```

Then deploy:

```bash
cd sandbox
terraform init -backend-config=../backend.hcl
terraform plan
terraform apply
```

---

## Workflow: Creating and reviewing a new module

1. **Generate** — Use `tf-architect` skill in Claude Code to scaffold a module
2. **Develop** — Edit module files (main.tf, variables.tf, etc.)
3. **Test locally** — Run `just` in the module directory to validate all checks
4. **Review code** — Use `tf-code-reviewer` skill or request peers
5. **Create PR** — GitHub Actions will run plan and checks automatically
6. **Deploy** — On merge to main, the apply workflow runs (after approval)

---

## AI Support

This repo includes AI skills that integrate with Claude Code and VS Code Copilot extensions:

| Skill | Use case |
|-------|----------|
| `tf-architect` | Scaffold new modules with full structure, tests, and backend config guidance |
| `tf-code-reviewer` | Review .tf files against standards, naming, and security rules |
| `repo-naming-checker` | Validate Azure resource names for compliance |
| `code-reviewer` | Review PowerShell, Bicep, and pipeline code |

**In Claude Code:**
```
# Ask Claude to generate a new module
"use tf-architect to generate an Azure App Service module"

# Ask to review your code
"use tf-code-reviewer to review the storage-account module"
```

---

## Next steps

✅ **Module is ready**: Your `storage-account` module passed all checks (`just` succeeded).

🎯 **What to do next**:

1. **Deploy bootstrap** (if not done):
   ```bash
   az deployment sub create -l norwayeast -f bootstrap/main.bicep \
     --parameters deploymentIdentityObjectId="<your-app-object-id>"
   ```

2. **Configure backend**:
   ```bash
   cp backend.hcl.example backend.hcl
   # (Edit if needed — values should match bootstrap output)
   ```

3. **Create a root deployment** (sandbox) to use the module:
   - Create `sandbox/main.tf` that calls the storage-account module
   - Create `sandbox/terraform.tf` with provider and version declarations
   - Run `terraform init -backend-config=../backend.hcl` and `terraform plan`

4. **Code review** (optional): Use `tf-code-reviewer` skill to review against standards before pushing

5. **Push to PR** and merge — GitHub Actions will handle plan/apply automatically
   | `providers.tf` | Provider configurations |
   | `main.tf` | Primary resources and data sources |
   | `variables.tf` | Input variable declarations (alphabetical) |
   | `outputs.tf` | Output value declarations (alphabetical) |
   | `locals.tf` | Local value declarations |
      

3. Check the AVM version — if the generated code references an `Azure/avm-res-storage-storageaccount` module, verify the version before accepting it:
   - `>= 1.0.0` → safe to use directly
   - `< 1.0.0` → ask the plugin to generate a custom module instead (see [AVM version rule](#avm-module-version-rule))

4. Apply team standards to the generated module. Ask Claude:

   > *"Apply Nimtech team standards to this module — add a `locals.tf` with `common_tags` (`environment`, `solution`, `owner`, `cost_center`), use the `st{env}{solution}` naming pattern via locals, and add `prevent_destroy = true` on the storage account."*

5. Review before committing. Ask Claude:

   > *"Review this module against team standards using the tf-code-reviewer skill."*

   Or in the Claude Code CLI:
   ```
   /tf-code-reviewer
   ```

See [`skills/tf-architect/SKILL.md`](skills/tf-architect/SKILL.md) for the full plugin guide.

### Initialise and plan

```bash
cd sandbox
terraform init -backend-config=backend.hcl
terraform plan
```

---

## Step 5 — Hands on terraform - Make a change and open a PR

Keep in mind when generating Terraform code:

1. Start with provider configuration and version constraints
2. Create data sources before dependent resources
3. Build resources in dependency order
4. Add outputs for key resource attributes
5. Use variables for all configurable values

**Excercise:**
1. **Add a resource** to `sandbox/main.tf` — e.g. a Key Vault, a managed identity, a VNet.
2. **Validate locally:**
   ```bash
   terraform fmt -recursive
   terraform validate
   tflint --recursive
   tfsec .
   ```
3. **Ask an AI to review it** before opening a PR (see [AI skills](#ai-skills) below).
4. **Open a PR** — the plan pipeline runs automatically and posts the plan output as a comment.
5. **Get it approved and merge** — the apply pipeline waits for a reviewer to approve on the `sandbox` GitHub environment, then applies.

---

## CI/CD pipeline

### On every pull request

Triggers when `.tf`, `.tfvars`, or workflow files change:

| Step | Tool | Failure means |
|------|------|---------------|
| Format check | `terraform fmt -check` | Run `terraform fmt -recursive` locally |
| Lint | `tflint` | Fix the flagged issues |
| Security scan | `tfsec` | Review and address findings |
| Validate | `terraform validate` | Fix syntax or config errors |
| Plan | `terraform plan` | Review the plan comment on the PR |

### On merge to main

Runs the same init, then `terraform apply -auto-approve` — but only after a reviewer approves on the `sandbox` GitHub environment.

---

## Team standards

All code is reviewed against the rules in `standards/templates/`:

| File | Purpose |
|------|---------|
| [`terraform-review.rules.md`](standards/templates/terraform-review.rules.md) | Terraform-specific checks: naming, tagging, state, AVM versions, security |
| [`code-review.rules.md`](standards/templates/code-review.rules.md) | Severity definitions and review principles |
| [`code-review.output.md`](standards/templates/code-review.output.md) | Required output format for all reviews |

### Naming convention

```
{type}-{env}{solution}
```

Example: `rg-dev-platform-iac-training`

Resource type prefixes follow the [Azure Cloud Adoption Framework abbreviations standard](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations). Common ones used in this repo:

| Resource | Abbreviation |
|----------|--------------|
| Resource group | `rg` |
| Storage account | `st` |
| Key vault | `kv` |
| AKS cluster | `aks` |
| Virtual network | `vnet` |
| Subnet | `snet` |
| Network security group | `nsg` |
| Managed identity | `id` |
| Container registry | `cr` |
| Log Analytics workspace | `log` |

Naming compliance is checked during AI code review (`/tf-code-reviewer`). It is **not** checked by CI — the reviewer MUST flag any deviation from the CAF standard or the `{type}-{env}{solution}` pattern as a **[BLOCKER]**.

### Required tags on every resource

```hcl
tags = {
  environment = var.environment   # dev / tst / uat / stg / prd
  solution    = var.solution
  owner       = var.owner
  cost_center = var.cost_center
}
```

### AVM module version rule

When using an `Azure/avm-*` module, always check the version:

| Version | Action |
|---------|--------|
| No `version` pinned | **[BLOCKER]** — pin immediately |
| `0.0.x` | **[BLOCKER]** — high-churn pre-release; build a custom module instead |
| `0.x.x` | **[MAJOR]** — pre-release; build a custom module instead |
| `>= 1.0.0` | ✅ Stable — safe to use |

Check current versions at [AVM Resource Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/).

---

## AI skills

### GitHub Copilot (VS Code)

Open agent mode (`@workspace`) — the skills in `skills/` are auto-discovered.

| Skill | Type `/` to invoke | Use for |
|-------|--------------------|---------|
| `tf-architect` | `/tf-architect` | Generating code, choosing between plugins, AVM version checks |
| `tf-code-reviewer` | `/tf-code-reviewer` | Reviewing `.tf` files or diffs |

### Claude Code (terminal)

Run `claude` in the repo root. `CLAUDE.md` loads automatically with plugin context.

```
/terraform-code-generation AKS cluster with system-assigned identity in West Europe
/terraform-module-generation reusable Azure Key Vault module with RBAC
```

---

## Exercises to get started

| # | Exercise | Skills practiced |
|---|----------|-----------------|
| 1 | Deploy the sandbox as-is — resource group + storage account | `terraform init`, `plan`, `apply`, backend config |
| 2 | Add a second resource to `sandbox/main.tf` and open a PR | PR workflow, plan output, CI pipeline |
| 3 | Write a reusable module in `modules/` for the resource from exercise 2 | Module structure, `variables.tf`, `outputs.tf` |
| 4 | Ask the AI to review your module — fix all [BLOCKER] and [MAJOR] findings | Code review workflow, team standards |
| 5 | Add a `locals.tf` with `common_tags` and wire it into all resources | Tag hygiene, locals pattern |
| 6 | Write a `.tftest.hcl` test for your module | Terraform native testing |

---

## References

- [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Resource Modules index](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
- [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style)
- [tfsec rules](https://aquasecurity.github.io/tfsec/)
- [tflint AzureRM rules](https://github.com/terraform-linters/tflint-ruleset-azurerm)


---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.9 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | latest | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| tflint | latest | [github.com/terraform-linters/tflint](https://github.com/terraform-linters/tflint) |
| tfsec | latest | [github.com/aquasecurity/tfsec](https://github.com/aquasecurity/tfsec) |
| Claude Code | latest | [claude.ai/code](https://claude.ai/code) |

```bash
az login
az account set --subscription "<your-sandbox-subscription-id>"
```

---

## Repository structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml     # Runs on PR — fmt, lint, security scan, plan
│   │   └── terraform-apply.yml    # Runs on merge to main — applies to sandbox
│   └── PULL_REQUEST_TEMPLATE.md
├── modules/                       # Reusable AVM-backed modules
│   └── storage-account/
├── sandbox/                       # Root configuration for the sandbox environment
├── skills/
│   └── tf-code-reviewer/          # Claude Code review skill
├── standards/
│   └── templates/                 # Coding and review standards
│       ├── terraform-review.rules.md
│       ├── code-review.rules.md
│       └── code-review.output.md
└── README.md
```

---

## Local setup for sandbox

1. Copy the backend config example and fill in your state storage details:

   ```bash
   cp sandbox/backend.hcl.example sandbox/backend.hcl
   # edit sandbox/backend.hcl with your values
   ```

2. Initialise and run:

   ```bash
   cd sandbox
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

---

## Recommended workflow

### 1 — Generate code

Ask Claude Code naturally — the HashiCorp plugins activate automatically based on context:

| Goal | Example prompt |
|---|---|
| New module | *"Generate a Terraform module for an Azure Key Vault using AVM"* |
| Refactor into a module | *"Refactor this resource into a reusable module"* |
| Write tests | *"Write a .tftest.hcl test for the storage account module"* |

### 2 — Adapt to team standards

Plugin-generated code is a starting point. Before opening a PR:

- [ ] Add `locals.tf` with `common_tags` (`environment`, `solution`, `owner`, `cost_center`)
- [ ] Wire `tags = local.common_tags` onto every resource
- [ ] Parameterise name arguments using the `{type}-{env}-{solution}` pattern via locals
- [ ] Add `backend "azurerm" {}` to root module `terraform.tf`
- [ ] Add `prevent_destroy = true` on stateful resources

Ask Claude to apply these for you:

> *"Apply Nimtech team standards to this module — add a `locals.tf` with `common_tags`, parameterise resource names using the `{type}-{env}-{solution}` pattern via locals, wire `tags = local.common_tags` onto every resource, and add `prevent_destroy = true` on stateful resources."*

### 3 — Check AVM module versions

Before accepting generated code that references an `Azure/avm-*` module:

| Version | Action |
|---|---|
| No `version` pinned | **[BLOCKER]** — pin immediately |
| `0.0.x` | **[MAJOR]** — high-churn pre-release, no stability guarantees |
| `0.x.x` | **[MINOR]** — flag for awareness; document acceptance before using in production |
| `>= 1.0.0` | ✅ Stable — use directly |

See [AVM Resource Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/) to check current versions.

### 4 — Validate locally

```bash
terraform fmt -recursive
terraform validate
tflint --recursive
tfsec .
```

### 5 — Review

Ask Claude to review before opening a PR.

**VS Code Claude extension** — select the file or open the chat and ask:

> *"Review this Terraform module against team standards using the tf-code-reviewer skill."*
> *"Review my changes in sandbox/main.tf against team standards."*

**Claude Code CLI:**

```
/tf-code-reviewer
```

Findings are reported as `[BLOCKER]` / `[MAJOR]` / `[MINOR]` / `[NIT]` with **Where / Why / Fix** for each. Fix all `[BLOCKER]` and `[MAJOR]` findings before opening a PR.

### 6 — Open a PR

CI runs automatically on every PR:
- Format check, lint, security scan, and plan
- Plan output is posted as a PR comment

---

## GitHub Actions pipeline

### On a pull request

The `terraform-plan` workflow triggers when `.tf` or `.tfvars` files change:

1. `terraform fmt -recursive -check`
2. `tflint`
3. `tfsec`
4. `terraform validate`
5. `terraform plan` — output posted as a PR comment

Fix formatting failures locally with `terraform fmt -recursive`.

### On merge to main

The `terraform-apply` workflow runs and **waits for approval** from a reviewer on the `sandbox` GitHub environment before applying.

To watch a deploy: **Actions → Terraform Apply → the running workflow**.

---

## GitHub setup (one-time)

### Secrets (Settings → Secrets and variables → Actions)

| Name | Description |
|---|---|
| `AZURE_CLIENT_ID` | Client ID of the app registration used for OIDC |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

### Variables (Settings → Secrets and variables → Actions → Variables)

| Name | Example |
|---|---|
| `TF_STATE_RESOURCE_GROUP` | `rg-dev-platform-terraform-state` |
| `TF_STATE_STORAGE_ACCOUNT` | `stdevplatformtfstate` |

### Azure OIDC (federated identity)

1. Create an **App Registration** in Azure AD.
2. Under **Certificates & secrets → Federated credentials**, add two credentials:
   - Entity type `Branch`, branch `main` (for applies)
   - Entity type `Pull request` (for plans)
3. Grant the app **Contributor** on the sandbox subscription (or scoped resource group).
4. Add the Client ID, Tenant ID, and Subscription ID as GitHub secrets above.

### GitHub environment

1. **Settings → Environments → New environment** — name it `sandbox`.
2. Add **Required reviewers** to gate applies behind an approval.

---

## AI skills (Claude Code)

### tf-code-reviewer

Reviews `.tf` files and diffs against HashiCorp style and team standards.

**VS Code Claude extension** — select the file or open the chat and ask:

> *"Review this Terraform module against team standards using the tf-code-reviewer skill."*
> *"Review my changes in sandbox/main.tf against team standards."*

**Claude Code CLI:**

```
/tf-code-reviewer
```

### HashiCorp plugins

Installed via `claude plugin install`. Active automatically based on context — no slash command needed.

| Plugin | Use for |
|---|---|
| `terraform-code-generation@hashicorp` | Generating resources, providers, backends |
| `terraform-module-generation@hashicorp` | Scaffolding reusable modules |
| `terraform-provider-development@hashicorp` | Building custom providers |

---

## Team conventions (Nimtech)

| Convention | Rule |
|---|---|
| Terraform symbolic names | `lower_snake_case`, descriptive nouns, singular |
| Azure resource names | `{type}-{env}-{solution}` pattern via locals |
| Required tags | `environment`, `solution`, `owner`, `cost_center` |
| Remote state | Azure Storage, provisioned via Bicep — never local state |
| Environment split | Separate state files for `can/` (canary) and `liv/` (live) |
| Secrets | No secrets in Terraform — Workload Identity + Key Vault references only |
| AVM preference | Use AVM for AKS, Key Vault, networking, and identity resources |

---

## Standards

- [Terraform coding standards](templates/terraform-review.rules.md)
- [Code review rules](templates/code-review.rules.md)
- [Code review output format](templates/code-review.output.md)

## References

- [HashiCorp Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Resource Modules index](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [tfsec](https://aquasecurity.github.io/tfsec/)

---

## Before using this in production

This repo is intentionally simplified for sandbox learning. The following changes are required before it is suitable for a production or shared environment.

### CI/CD pipeline

| # | File | Issue | What to do |
|---|------|-------|------------|
| 1 | `.github/workflows/terraform-plan.yml` | `tfsec` is downloaded without checksum verification — a compromised binary could silently pass or fail security scans | Pin to a specific version and verify the SHA256 checksum against the [tfsec releases page](https://github.com/aquasecurity/tfsec/releases) before executing |
| 2 | `.github/workflows/terraform-plan.yml` | `terraform plan` output is posted to PR comments unsanitised — plan output can contain sensitive values from state (connection strings, keys, resource IDs) | Filter or redact sensitive lines before posting, or replace the script with a dedicated tool such as [tfcmt](https://github.com/suzuki-shunsuke/tfcmt) which supports masking |
| 3 | `.github/workflows/terraform-apply.yml` | `terraform apply -auto-approve` does not use a saved plan file — if the environment approval gate is misconfigured the apply runs without a reviewed plan | Replace with a two-step approach: save the plan in the plan workflow (`-out=tfplan`), upload it as an artifact, download and apply it in the apply workflow (`terraform apply tfplan`) |

### Terraform code

| # | File | Issue | What to do |
|---|------|-------|------------|
| 4 | `sandbox/outputs.tf` | Outputs are not marked `sensitive = true` — if future outputs include keys or connection strings they will appear in plain text in logs and plan comments | Add `sensitive = true` to any output that may carry a secret value |
| 5 | `sandbox/variables.tf` | The `owner` variable has no format validation | Add a `validation` block enforcing an email pattern |
