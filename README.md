# IaC Training — Terraform on Azure

This repo is the starting point for Nimtech infrastructure consultants learning Infrastructure as Code with Terraform. It provides a working sandbox environment, a CI/CD pipeline, team coding standards, and AI-assisted tooling.

---

## What's in here

```
.
├── .github/
│   └── workflows/
│       ├── _terraform-plan.yml    # Reusable plan/validate workflow
│       └── terraform-plan.yml     # Sandbox caller — triggers on sandbox/** PRs
├── bootstrap/
│   └── main.bicep                 # One-time: provisions Terraform state storage
├── backend.hcl                    # gitignored — points to state storage (fill in locally)
├── modules/
│   └── storage-account/           # Reusable storage account module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── locals.tf
│       ├── terraform.tf
│       ├── providers.tf
│       ├── Justfile               # Local dev commands
│       └── environments/
│           └── sbx.tfvars
├── sandbox/                       # Deployment: calls modules/storage-account
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   ├── providers.tf
│   ├── Justfile                   # Local dev commands
│   └── environments/
│       └── sbx.tfvars
├── skills/                        # Claude Code AI skills
│   ├── tf-architect/              # Scaffold Terraform modules and deployments
│   ├── github-actions-cicd/       # Generate GitHub Actions workflows
│   ├── tf-code-reviewer/          # Review .tf files against standards
│   └── naming-checker/            # Validate Azure resource naming
├── standards/
│   └── templates/                 # Authoring guides and review rules
├── CLAUDE.md                      # Claude Code context — loaded automatically
└── README.md
```

---

## Prerequisites

| Tool | Install |
|------|---------|
| Terraform ≥ 1.6 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Just | [just.systems](https://just.systems/man/en/packages.html) |
| tflint | [github.com/terraform-linters/tflint](https://github.com/terraform-linters/tflint) |
| tfsec | [github.com/aquasecurity/tfsec](https://github.com/aquasecurity/tfsec) |
| Claude Code | [claude.ai/code](https://claude.ai/code) |

After installing tflint, run `tflint --init` in the repo root to install the azurerm ruleset.

---

## Step 1 — Bootstrap (one-time, platform admin)

Terraform state is stored in an Azure Storage Account provisioned by the Bicep bootstrap template. This runs once per subscription before any Terraform deployments.

```bash
# Get your app registration Object ID
az ad sp show --id <AZURE_CLIENT_ID> --query id -o tsv

# Deploy the state backend
az deployment sub create \
  --location norwayeast \
  --template-file bootstrap/main.bicep \
  --parameters deploymentIdentityObjectId="<object-id>"
```

This creates:
- Resource group: `rg-sbx-platform-terraform-state`
- Storage account: `stsbxplatformtfstate`
- Container: `tfstate`
- RBAC: `Storage Blob Data Owner` for the app registration

---

## Step 2 — GitHub setup (one-time, platform admin)

### Azure OIDC — no long-lived secrets

1. Create an **App Registration** in Azure AD.
2. Under **Certificates & secrets → Federated credentials**, add:
   - Entity type: `Pull request` — used by the plan pipeline
   - Entity type: `Branch`, branch `main` — used by an apply pipeline if added later
3. Grant the app **Contributor** on the sandbox subscription (or scoped resource group).

### Secrets (`Settings → Secrets and variables → Actions → Secrets`)

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Sandbox subscription ID |

### Variables (`Settings → Secrets and variables → Actions → Variables`)

| Variable | Value |
|----------|-------|
| `TF_BACKEND_RESOURCE_GROUP` | `rg-sbx-platform-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | `stsbxplatformtfstate` |

> Backend config values are **variables**, not secrets — using `secrets.*` for these silently returns empty.

---

## Step 3 — Local backend config

`backend.hcl` is gitignored and must be filled in locally before running `terraform init`:

```hcl
# backend.hcl (already present at repo root — fill in your values)
resource_group_name  = "rg-sbx-platform-terraform-state"
storage_account_name = "stsbxplatformtfstate"
container_name       = "tfstate"
key                  = "sandbox/terraform.tfstate"
```

---

## Development workflow

### Creating a new Terraform module

Use the `tf-architect` skill in Claude Code. It walks you through module requirements and generates all files conforming to team standards:

```
use tf-architect to scaffold an Azure Key Vault module
```

The skill generates: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`, `providers.tf`, `Justfile`, and `environments/<env>.tfvars`.

### Scaffolding a new deployment (e.g. sandbox)

Use `tf-architect` for deployments too — tell it which module to deploy and which environment:

```
use tf-architect to scaffold a sandbox deployment of the storage-account module
```

### Setting up CI/CD for a deployment

Use the `github-actions-cicd` skill. It asks for the module path, tfvars file, and whether you want an apply workflow, then generates fully standards-compliant workflow files:

```
use github-actions-cicd to set up a plan workflow for the sandbox deployment
```

The skill produces:
- `.github/workflows/_terraform-plan.yml` — reusable workflow (parameterised)
- `.github/workflows/terraform-plan.yml` — caller scoped to your deployment path

### Local development

Each deployment directory has a `Justfile` with these targets:

```bash
cd sandbox

just validate   # terraform init (no backend) + validate
just fmt        # terraform fmt -recursive
just lint       # tflint --recursive
just plan       # terraform init (with backend.hcl) + plan -var-file=environments/sbx.tfvars
just apply      # terraform init (with backend.hcl) + apply -var-file=environments/sbx.tfvars
just            # runs fmt → validate → lint (default)
```

`just plan` and `just apply` read `../backend.hcl` — make sure it is filled in first.

### Opening a PR

Push your branch and open a PR against `main`. The plan pipeline triggers automatically on any change under `sandbox/**`:

1. **Validate job** — fmt check, tflint, `terraform validate`, tfsec
2. **Plan job** (runs only if validate passes) — `terraform init` + `terraform plan`, plan output posted as a PR comment, binary plan uploaded as an artifact

Fix any failures, then get a review and merge.

---

## CI/CD pipeline

### `terraform-plan.yml` (PR trigger)

Triggers on pull requests to `main` that change files under `sandbox/**`.

| Job | Steps |
|-----|-------|
| `validate` | fmt check, tflint (cached), `terraform init -backend=false`, `terraform validate`, tfsec |
| `plan` | OIDC init (inline backend config), `terraform plan`, plan comment on PR, artifact upload |

The reusable workflow `_terraform-plan.yml` is parameterised — adding CI/CD for a new deployment is a new thin caller file, no copy-paste.

### Apply workflow

No apply workflow is configured yet. To add one, run:

```
use github-actions-cicd to add an apply workflow for the sandbox deployment
```

---

## AI skills (Claude Code)

All skills are invoked through Claude Code. In VS Code, use the chat panel. In the terminal, run `claude` from the repo root.

| Skill | When to use | How to invoke |
|-------|-------------|---------------|
| `tf-architect` | Scaffold a new module or deployment | `use tf-architect to scaffold...` |
| `github-actions-cicd` | Generate plan/apply workflows | `use github-actions-cicd to set up CI/CD for...` |
| `tf-code-reviewer` | Review .tf files against standards | `use tf-code-reviewer to review...` |
| `naming-checker` | Validate Azure resource naming | `use naming-checker to check...` |

`CLAUDE.md` is loaded automatically and configures all skills — no manual setup required.

---

## Standards

All code is written and reviewed against:

| File | Purpose |
|------|---------|
| [`standards/templates/terraform-authoring-guide.md`](standards/templates/terraform-authoring-guide.md) | Module structure, naming, variables, outputs, tagging |
| [`standards/templates/terraform-standards.md`](standards/templates/terraform-standards.md) | Single source of truth — review rules, formatting, naming, security, AVM, testing |
| [`standards/templates/github-actions-best-practices.md`](standards/templates/github-actions-best-practices.md) | Workflow structure, OIDC, SHA pinning |
| [`standards/templates/naming-conventions.md`](standards/templates/naming-conventions.md) | Azure resource naming rules |

### Required tags on every resource

```hcl
tags = local.common_tags   # defined in locals.tf

locals {
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
```

### Naming pattern

```
{type}-{environment}-{solution}   # resource groups, vnets, etc.
st{environment}{solution}          # storage accounts (no hyphens, max 24 chars)
```

---

## References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style)
- [tflint azurerm ruleset](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [tfsec rules](https://aquasecurity.github.io/tfsec/)
