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

If the user said yes to question nr 3: invoke the `repo-naming-checker` skill to gather information — do not rely on inline naming rules here.

Read [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md) in full.

Generate the following files, conforming to the authoring guide:

| File | Contents |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version` and `required_providers` only — no provider config |
| `providers.tf` | Provider configurations (e.g. `provider "azurerm" { features {} }`) |
| `main.tf` | Resources in dependency order |
| `data.tf` | Data sources only — omit if the module has no data sources |
| `variables.tf` | All input variables — alphabetical, each with `type`, `description`, and `validation` where values are constrained |
| `outputs.tf` | All outputs — alphabetical, each with `description`; sensitive outputs marked `sensitive = true` |
| `locals.tf` | Local values for name construction and the `common_tags` map |
| `environments/dev.tfvars` | Sample environment file with structural vars only — no secrets |
| `tests/<resource>.tftest.hcl` | Native Terraform test (see testing section below) |
| `Makefile` | Shortcuts for validate, fmt, security scan, and test (see testing section below) |

Produce all files in full before moving on.

### Root-level backend configuration

**Important:** After generating module files, ensure your **root-level deployment** (e.g., a `sandbox/` directory or top-level config) has a `backend.hcl` configuration that points to the bootstrapped Terraform state storage.

If a `bootstrap/` directory exists in the repo with a `main.bicep` file, it creates the storage account for state. Generate or create a `backend.hcl.example` template at the root level showing:

```hcl
resource_group_name  = "rg-{environment}-{solution}-terraform-state"
storage_account_name = "st{environment}{solution}tfstate"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

Instruct the user to:
1. Copy `backend.hcl.example` → `backend.hcl`
2. Fill in the resource group, storage account, and key values to match their bootstrap deployment
3. Run `terraform init -backend-config=backend.hcl` before planning or applying

**Module versioning** — If the user says yes to question 4: scaffold the files inside a `v1.0.0/` subfolder and increment for breaking changes so versions can coexist. If the user says no, follow the existing directory pattern instead.

```
modules/<resource-type>/
└── v1.0.0/          ← use if the project applies versioning
    ├── terraform.tf
    ├── providers.tf
    ├── main.tf
    ├── data.tf        ← omit if no data sources
    ├── variables.tf
    ├── outputs.tf
    ├── locals.tf
    ├── Makefile
    ├── environments/
    │   └── dev.tfvars
    └── tests/
        └── <resource>.tftest.hcl
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
> 1. `repo-naming-checker` — validates all Azure resource names, variable names, and file names
> 2. `tf-code-reviewer` — reviews code correctness, security, and team standards
>
> Run both now, or skip if you would prefer to review manually?

If the user proceeds, invoke the skills in the order listed. **`repo-naming-checker` must return zero blockers and zero majors before `tf-code-reviewer` is invoked.** If naming violations are found, resolve them first, then proceed to the code review. Present all findings together before moving on. If findings are returned, work through them with the user before the PR is raised.

Note: `tf-code-reviewer` will also run automatically on the PR via GitHub Actions.

## Standards

All generated code must conform to [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md).
