---
name: tf-architect
description: "Scaffold and generate Terraform modules for Azure infrastructure, including resources, variables, outputs, and environment configurations. Handles naming conventions, versioning, test scaffolding, and code review integration."
argument-hint: "Describe the Azure infrastructure or module you want to build"
---

# Terraform Architect

Guide the user step-by-step through creating a Terraform module for Azure, following team standards.

## Step 0 — Detect intent

Before asking any questions, check whether the user's request names existing modules. Use the Glob tool to test for the presence of `infra-as-code/terraform/modules/<module-name>/` for each module mentioned.

- If **all named modules exist** → enter **deployment-only mode** (Step 1A)
- If **any named module does not exist**, or the user is asking to create a new module from scratch → enter **new-module mode** (Step 1B)

---

## Step 1A — Deployment-only mode

Use this path when the user wants to wire existing modules into a new solution (deployment root).

Ask the following questions **one at a time**:

**D-Q1**
> What environments do you need a `tfvars` file for?
> - A) `dev`
> - B) `can`
> - C) `sbx`
> - D) Other (describe)
>
> *(multi-select — you can pick more than one)*

**D-Q2**
> Do the existing modules cover all required functionality, or is new functionality needed?
> - A) Existing modules are sufficient — generate the deployment root as-is
> - B) New functionality is needed — describe what is missing
>
> If B: collect the description, then proceed through **Step 1B** to scaffold a new module version (e.g. `v2.0.0`) before continuing to generate the deployment root.

After collecting D-Q1 and D-Q2, confirm your understanding before generating.


---

## Step 1B — New-module mode

Use this path when a named module does not yet exist, or when the user chose "new functionality needed" in D-Q2.

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

---

## Step 1.5 — AVM check gate (new-module mode only)

Before writing any resources, check whether an Azure Verified Module (AVM) exists for the resource type being built.

Known AVM mappings for common resources:

| Resource | AVM module source |
|---|---|
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` |
| AKS | `Azure/avm-res-containerservice-managedcluster/azurerm` |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` |
| User Assigned Identity | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` |

For resource types not in the table above, search registry.terraform.io for `Azure/avm-res-<resource-type>` before assuming no AVM exists.

If an AVM module exists, present this question to the user before proceeding:

> An AVM module exists for this resource: `<avm-source>`
>
> How would you like to proceed?
> - A) **Use AVM** — the generated module will call the AVM module and expose a team-standard variable/output interface on top of it
> - B) **Custom implementation** — build from scratch using `azurerm` resources directly; add a comment in `main.tf` explaining why AVM was not used

If **no AVM exists** for the resource type, note this and proceed directly to Step 2 without asking.

**Version guidance:** Pin an explicit version. Prefer the latest non-`0.0.x` release. `0.x.x` versions are acceptable if that is the current AVM release track — the rule is to avoid `0.0.x` patch-zero pre-releases, not all `0.x.x` versions.

**If the user selects AVM (option A), fetch the module interface before writing any code:**

Using the resolved version (e.g. `v0.5.3`), fetch both files from GitHub using WebFetch:

```
https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-<resource>/v<version>/variables.tf
https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-<resource>/v<version>/outputs.tf
```

Read both files in full. Do not infer or assume the AVM interface — every input variable name and every output name used in the wrapper module must come from these files. Using an attribute that does not exist in the AVM outputs is a hard error at test time.

---

## Step 2 — Generate

### Deployment-only mode (Step 1A path)

Before writing any code, read the following using the Read tool directly — do not delegate to a subagent:

1. `variables.tf` and `outputs.tf` for **each referenced module** — these define the exact interface to pass through
2. [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md) — authoring standards
3. [`../../standards/templates/naming-conventions.md`](../../standards/templates/naming-conventions.md) — naming rules

Then generate the **deployment root only** under `solutions/<solution-name>/`. Do **not** create any module files — source paths in `main.tf` point to the existing versioned modules.

When building `variables.tf` for the deployment root: union all variables from the referenced modules, deduplicating shared ones (`environment`, `solution`, `location`, `owner`, `cost_center`, `resource_group_name`). Module-specific variables (e.g. `replication_type`, `sku_name`) are each included once.

Follow the same file structure as `solutions/application-1/` (the reference implementation):

| File | Contents |
|---|---|
| `terraform.tf` | `required_version`, `required_providers`, `backend "azurerm" {}` |
| `providers.tf` | `provider "azurerm" { features {} }` |
| `locals.tf` | `resource_group_name` and `common_tags` locals |
| `main.tf` | `azurerm_resource_group.main`, then one `module` block per referenced module with all variables passed through |
| `variables.tf` | Union of all module variables (deduplicated) |
| `outputs.tf` | Re-exposes module outputs via `module.<name>.<output>` |
| `environments/<env>.tfvars` | One file per environment chosen in D-Q1 |
| `Taskfile.yml` | Copied from application-1 pattern, with solution name substituted |

---

### New-module mode (Step 1B path)

Before writing any terraform code:

If the user said yes to question nr 3: invoke the `naming-checker` skill to gather information — do not rely on inline naming rules here.

Read the following documents in full using the Read tool directly — do not delegate to a subagent or rely on a summary. Every section is load-bearing; summarisation has historically caused sections to be silently skipped.

1. [`../../standards/templates/terraform-authoring-guide.md`](../../standards/templates/terraform-authoring-guide.md) — authoritative guide for generative work, including the AVM check gate
2. [`../../standards/templates/naming-conventions.md`](../../standards/templates/naming-conventions.md) — naming rules that must inform code generation, not just post-generation review. Pay particular attention to: environment token rules (`can`/`liv` only — `canary`/`live` is a BLOCKER), CAF abbreviations, and storage account constraints (no dashes, lowercase, 3-24 chars). Apply these rules when constructing names in `locals.tf`.

**Identity:** Prefer `UserAssigned` managed identity to `SystemAssigned`, unless the resource type explicitly does not support user-assigned identities. Create or reuse a dedicated `user assigned identity` module and pass its ID via `identity_ids`. Never default to `SystemAssigned` without documented justification.

**Resource group ownership:** Modules never create their own resource group. The deployment root (solution) creates the resource group and passes `resource_group_name` to each module. Every module must declare a required `resource_group_name` variable. This allows multiple modules in the same solution to share a single resource group. The solution should also define a `locals` block with `resource_group_name` and `common_tags`, and create `azurerm_resource_group.main` before any module calls.

Generate two sets of files — the reusable **module** and the **deployment root** that calls it. These are always separate directories with distinct responsibilities.

**CRITICAL: `providers.tf` belongs in the deployment root only — never in the module.** Provider blocks inside modules are forbidden by team standards. The module declares `required_providers` in `terraform.tf` so Terraform knows what it needs, but the actual `provider {}` configuration always lives in the deployment root.

#### Module files — `modules/<resource-type>/v1.0.0/`

| File | Contents |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version = "~> 1.9"` and `required_providers` (hashicorp/azurerm `~> 4.0`) only — no provider config, no backend block |
| `main.tf` | Resources in dependency order |
| `data.tf` | Data sources only — omit if the module has no data sources |
| `variables.tf` | All input variables — alphabetical, each with `type`, `description`, and `validation` where values are constrained |
| `outputs.tf` | All outputs — alphabetical, each with `description`; sensitive outputs marked `sensitive = true` |
| `locals.tf` | Local values for name construction and the `common_tags` map |
| `tests/<resource>.tftest.hcl` | Native Terraform test (see testing section below) |
| `Taskfile.yml` | Targets: `validate`, `fmt`, `lint`, `test`, `all` |

#### Deployment root files — `solutions/<solution-name>/`

| File | Contents |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version`, `required_providers`, and `backend "azurerm" {}` |
| `providers.tf` | Provider configurations (e.g. `provider "azurerm" { features {} }`) |
| `main.tf` | `module "<resource_type>" { source = "../../modules/<resource-type>/v1.0.0" ... }` — passes all variables through |
| `variables.tf` | Same variables as the module — drives what gets passed in |
| `outputs.tf` | Re-exposes module outputs via `module.<name>.<output>` |
| `environments/<env>.tfvars` | Environment-specific values — structural only, no secrets |

The deployment root follows the same pattern as `solutions/application-1/` in this repo — use that as a reference implementation. The solution name (e.g. `application-1`, `application-2`) becomes the folder name under `solutions/`.

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
    ├── Taskfile.yml
    └── tests/
        └── <resource>.tftest.hcl

solutions/<solution-name>/
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

- Declare a `mock_provider` block for **every provider** the module requires — this removes the need for real credentials and is required for plan-only tests
- Declare a `variables {}` block supplying all required inputs (use non-production values)
- Include at least one `run` block that calls `plan` and asserts a key output or resource attribute
- Never contain real secrets — use placeholder strings

Example structure:

```hcl
mock_provider "azurerm" {}

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

If the module uses AVM (which requires both `azurerm` and `azapi`), declare both. Additionally, if the module contains a data source whose computed attribute is passed to an `azapi` resource that validates the value format (e.g. `parent_id` must start with `/`), override the data source mock with a valid-format value — otherwise the mock will generate a random string and the plan will fail:

```hcl
mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sbx-example"
    }
  }
}
```

### Backend configuration for deployment

The repo uses inline `-backend-config` flags — no `backend.hcl` file is needed or committed. The `Taskfile.yml` in each solution constructs the backend config from the `ENV` variable (default: `sbx`).

The bootstrap (one-time, already done for existing environments) provisions the state storage account via Bicep:

```bash
az deployment sub create \
  --location norwayeast \
  --template-file infra-as-code/bicep/bootstrap/main.bicep \
  --parameters infra-as-code/bicep/bootstrap/config/parameters/sbx.bicepparam \
  --parameters deploymentIdentityObjectId="<object-id>"
```

The generated `Taskfile.yml` for the solution handles init inline:

```yaml
terraform init \
  -backend-config="resource_group_name=rg-{{.ENV}}-platform-terraform-state" \
  -backend-config="storage_account_name=st{{.ENV}}platformtfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<solution-name>/terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
```

Run locally with `task plan` (defaults to `sbx`) or `ENV=prd task plan` to target another environment.

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

3. Run the tests:
   ```bash
   terraform test
   ```

   For formatting, linting, and validation, run from the consuming solution or repo root:
   ```bash
   terraform fmt -recursive
   tflint --recursive
   terraform validate
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
