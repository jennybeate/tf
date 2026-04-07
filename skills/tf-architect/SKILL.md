---
name: tf-architect
description: "Scaffold and generate Terraform modules for Azure infrastructure, including resources, variables, outputs, and environment configurations. Handles naming conventions, versioning, test scaffolding, and code review integration."
argument-hint: "Describe the Azure infrastructure or module you want to build"
---

# Terraform Architect

Guide the user step-by-step through creating a Terraform module for Azure, following team standards.

## Step 1 — Understand the goal

Before searching for context, if the user has not already described what they need, ask:

> What Azure infrastructure or module do you want to build? Describe the resource(s), the deployment context, and any specific requirements (e.g. private endpoints, managed identity, environment split).

Ask the following questions **one at a time** — present the question with its labeled options, wait for the user's answer, then move to the next. Do not show multiple questions at once.

**Q1**
> Will `environment` and `solution` be the two variables that drive resource naming and tags — or do you need additional variables in the name?
> - A) Yes — `environment` and `solution` are sufficient
> - B) No — I need additional variables (describe)

**Q2**
> What environments do you need a `tfvars` file for?
> - A) `dev`
> - B) `can`
> - C) `sbx`
> - D) Other (describe)
>
> *(multi-select — you can pick more than one)*

**Q3**
> Do you want to follow company naming standards for resources, variables, and files?
> - A) Yes
> - B) No

**Q4**
> Do you want to use module versioning?
> - A) Yes — scaffold inside a `v1.0.0/` subfolder
> - B) No — place files directly in the module folder

**Q5**
> Which capabilities should the module support?
> - A) Private endpoint
> - B) Blob soft delete + versioning
> - C) Lifecycle management
> - D) Diagnostic settings to Log Analytics
> - E) None — basic storage account only
>
> *(multi-select — you can pick more than one)*

After all five answers are collected, confirm your understanding before moving on.

## Step 2 — Generate the module

Before writing any terraform code:

If the user said yes to question nr 3: invoke the `naming-checker` skill to gather information — do not rely on inline naming rules here.

Read the following documents in full using the Read tool directly — do not delegate to a subagent or rely on a summary. Every section is load-bearing; summarisation has historically caused sections to be silently skipped.

1. [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md) — authoritative guide for generative work, including the AVM check gate
2. [`../../standards/templates/naming-conventions.md`](../../standards/templates/naming-conventions.md) — naming rules that must inform code generation, not just post-generation review. Pay particular attention to: environment token rules (`can`/`liv` only — `canary`/`live` is a BLOCKER), CAF abbreviations, and storage account constraints (no dashes, lowercase, 3-24 chars). Apply these rules when constructing names in `locals.tf`.

**Identity:** Always use `UserAssigned` managed identity, not `SystemAssigned`, unless the resource type explicitly does not support user-assigned identities. Create a dedicated `azurerm_user_assigned_identity` resource named `id-{environment}-{solution}` and pass its ID via `identity_ids`. Never default to `SystemAssigned` without documented justification.

**Resource group ownership:** Modules never create their own resource group. The deployment root (solution) creates the resource group and passes `resource_group_name` to each module. Every module must declare a required `resource_group_name` variable. This allows multiple modules in the same solution to share a single resource group. The solution should also define a `locals` block with `resource_group_name` and `common_tags`, and create `azurerm_resource_group.main` before any module calls.

Generate two sets of files — the reusable **module** and the **deployment root** that calls it. These are always separate directories with distinct responsibilities.

**CRITICAL: `providers.tf` belongs in the deployment root only — never in the module.** Provider blocks inside modules are forbidden by team standards. The module declares `required_providers` in `terraform.tf` so Terraform knows what it needs, but the actual `provider {}` configuration always lives in the deployment root.

#### Module files — `modules/<resource-type>/v1.0.0/`

| File | Contents |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version` and `required_providers` only — no provider config, no backend block |
| `main.tf` | Resources in dependency order |
| `data.tf` | Data sources only — omit if the module has no data sources |
| `variables.tf` | All input variables — alphabetical, each with `type`, `description`, and `validation` where values are constrained |
| `outputs.tf` | All outputs — alphabetical, each with `description`; sensitive outputs marked `sensitive = true` |
| `locals.tf` | Local values for name construction and the `common_tags` map |
| `tests/<resource>.tftest.hcl` | Native Terraform test (see testing section below) |
| `Makefile` | Shortcuts for validate, fmt, security scan, and test (see testing section below) |

#### Deployment root files — `deployments/<resource-type>/`

| File | Contents |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version`, `required_providers`, and `backend "azurerm" {}` |
| `providers.tf` | Provider configurations (e.g. `provider "azurerm" { features {} }`) |
| `main.tf` | `module "<resource_type>" { source = "../../modules/<resource-type>/v1.0.0" ... }` — passes all variables through |
| `variables.tf` | Same variables as the module — drives what gets passed in |
| `outputs.tf` | Re-exposes module outputs via `module.<name>.<output>` |
| `environments/<env>.tfvars` | Environment-specific values — structural only, no secrets |

The deployment root follows the same pattern as `sandbox/` in this repo. Look at `sandbox/` for a reference implementation.

**Module versioning** — If the user says yes to question 4: scaffold the module files inside a `v1.0.0/` subfolder. The deployment root does not use version subfolders.

```
modules/<resource-type>/
└── v1.0.0/
    ├── terraform.tf       ← required_version + required_providers only
    ├── main.tf
    ├── data.tf            ← omit if no data sources
    ├── variables.tf
    ├── outputs.tf
    ├── locals.tf
    ├── Makefile
    └── tests/
        └── <resource>.tftest.hcl

deployments/<resource-type>/
    ├── terraform.tf       ← required_version + required_providers + backend "azurerm" {}
    ├── providers.tf       ← provider "azurerm" { features { ... } }
    ├── main.tf            ← module block calling modules/<resource-type>/v1.0.0
    ├── variables.tf
    ├── outputs.tf
    └── environments/
        └── <env>.tfvars
```

### Testing scaffold

Generate a `tests/<resource>.tftest.hcl` using Terraform's built-in test framework (requires Terraform ≥ 1.6). The test file must:

- Declare a `variables {}` block supplying all required inputs (use non-production values)
- Include at least one `run` block that calls `plan` and asserts a key output or resource attribute
- Never contain real secrets — use placeholder strings

Example structure:

```hcl
variables {
  environment  = "dev"
  solution     = "example"
  location     = "norwayeast"
  owner        = "platform-team"
  cost_center  = "cc-0000"
}

run "storage_account_is_created" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.min_tls_version == "TLS1_2"
    error_message = "Storage account must enforce TLS 1.2."
  }
}
```

Generate a `Makefile` at the module root with these targets:

```makefile
.PHONY: validate fmt lint security test

validate:
	terraform init -backend=false
	terraform validate

fmt:
	terraform fmt -recursive

lint:
	tflint --recursive

security:
	tfsec .

test:
	terraform test

all: fmt validate lint security test
```

### Backend configuration for deployment

If your repository has a `bootstrap/` directory with Bicep infrastructure-as-code, it provisions a storage account for Terraform state. Before deploying your Terraform modules, configure the backend:

1. Deploy the bootstrap infrastructure first (one-time):
   ```bash
   az deployment sub create -l norwayeast -f bootstrap/main.bicep
   ```

2. Copy the `backend.hcl.example` file to `backend.hcl` at the root level and fill in the values to match your bootstrap deployment

3. When deploying modules, initialize Terraform with the backend config:
   ```bash
   terraform init -backend-config=backend.hcl
   ```

### Testing instructions for users

After generating all files, present the following instructions to the user:

---

**Running the tests**

1. Install prerequisites (once):
   - [Terraform ≥ 1.6](https://developer.hashicorp.com/terraform/install)
   - [tflint](https://github.com/terraform-linters/tflint) — `brew install tflint` / `choco install tflint`
   - [tfsec](https://aquasecurity.github.io/tfsec) — `brew install tfsec` / `choco install tfsec`

2. Navigate to the module directory:
   ```bash
   cd modules/<resource-type>/v1.0.0   # adjust path as needed
   ```

3. Run all checks at once:
   ```bash
   make all
   ```

   Or run individual targets:
   ```bash
   make validate   # initialise (no backend) + validate HCL
   make fmt        # auto-format all .tf files
   make lint       # tflint static analysis
   make security   # tfsec security scan
   make test       # terraform test (runs tests/*.tftest.hcl)
   ```

4. The `terraform test` command runs in-process — it does **not** deploy real Azure resources unless you add a `run { command = apply }` block and supply valid credentials.

---

## Step 3 — Review the generated code together

Walk through the output with the user:

> Here is the generated module. Before you make your edits, let me know if anything needs adjusting — resource configuration, variable defaults, naming, or structure.

Apply any corrections, then tell the user:

> The scaffold is ready. Make your project-specific edits now — variable values, resource configuration, naming, tags — then let me know when you are done and we will run the code review.

Wait for the user to confirm they are done editing.

## Step 4 — Trigger the code review

Once the user confirms their edits are complete, ask:

> Ready to run the code review? I will invoke two skills in sequence:
>
> 1. `naming-checker` — validates all Azure resource names, variable names, and file names
> 2. `tf-code-reviewer` — reviews code correctness, security, and team standards
>
> Run both now, or skip if you would prefer to review manually?

If the user proceeds, invoke the skills in the order listed. **`naming-checker` must return zero blockers and zero majors before `tf-code-reviewer` is invoked.** If naming violations are found, resolve them first, then proceed to the code review. Present all findings together before moving on. If findings are returned, work through them with the user before the PR is raised.

Note: `tf-code-reviewer` will also run automatically on the PR via GitHub Actions.

## Standards

All generated code must conform to [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md).
