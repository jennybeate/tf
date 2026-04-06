# Terraform Authoring Guide

This guide is to help you define how to write Terraform modules for Azure at Nimtech. It is the source of truth for generative work — what to do and how to do it. For review checks and what will be flagged, see `terraform-standards.md`.

## Before you start — AVM check

**Prefer Azure Verified Modules (AVM) over custom implementations for standard Azure resources: AKS, Key Vault, networking, and identity.**

Check the AVM catalogue before writing any resources. Only proceed with a custom module if:
- No AVM module exists for the resource type, or
- You have documented justification (add a comment or README explaining why)

Always pin an explicit version — never use a floating reference:

```hcl
# ✅ GOOD — pinned stable version
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.0"
}

# ❌ BAD — unpinned, will silently pull breaking changes
module "key_vault" {
  source = "Azure/avm-res-keyvault-vault/azurerm"
}
```

Avoid `0.0.x` versions in production — these are high-churn pre-release builds with no stability guarantees.

---

## File structure

Every Terraform codebase has two distinct layers with different responsibilities. **Never mix them.**

### Reusable module — `modules/<resource-type>/v1.0.0/`

| File | Purpose |
|---|---|
| `terraform.tf` | `required_version` and `required_providers` only — no provider config, no backend block |
| `main.tf` | Resources and data sources in dependency order |
| `data.tf` | Data sources only — omit if none |
| `variables.tf` | Input variable declarations — alphabetical |
| `outputs.tf` | Output declarations — alphabetical |
| `locals.tf` | Local values used to avoid repetition and construct names |

**`providers.tf` does not belong in a module.** Provider blocks inside modules are forbidden — the calling deployment root owns provider configuration. The module only declares `required_providers` in `terraform.tf` so Terraform knows what provider it depends on.

### Deployment root — `deployments/<resource-type>/`

| File | Purpose |
|---|---|
| `terraform.tf` | `required_version`, `required_providers`, and `backend "azurerm" {}` |
| `providers.tf` | Provider configurations (`provider "azurerm" { features { ... } }`) |
| `main.tf` | `module` block(s) calling the reusable module, passing all variables through |
| `variables.tf` | Input variables — mirrors the module's variables |
| `outputs.tf` | Re-exposes module outputs via `module.<name>.<output>` |
| `environments/<env>.tfvars` | Environment-specific values — structural only, no secrets |

See `sandbox/` in this repo as a reference deployment root.

Versioning applies to modules only — use a `v1.0.0/` subfolder and increment for breaking changes. Deployment roots do not use version subfolders.

```
modules/<resource-type>/
└── v1.0.0/
    ├── terraform.tf       ← required_version + required_providers only
    ├── main.tf
    ├── data.tf            ← omit if no data sources
    ├── variables.tf
    ├── outputs.tf
    └── locals.tf

deployments/<resource-type>/
    ├── terraform.tf       ← required_version + required_providers + backend "azurerm" {}
    ├── providers.tf       ← provider "azurerm" { features { ... } }
    ├── main.tf            ← module block calling modules/<resource-type>/v1.0.0
    ├── variables.tf
    ├── outputs.tf
    └── environments/
        └── <env>.tfvars
```

## Naming

Follow the naming patterns in [`naming-conventions.md`](naming-conventions.md). For Terraform specifically:

- Construct all Azure resource names in `locals.tf` — never hardcode a name inside a resource block
- Build a `common_tags` local in `locals.tf` and apply it to every resource
- Terraform resource labels must be lowercase with underscores (`my_resource_group`), not hyphens or camelCase
- Use singular labels (`web_server`, not `web_servers`)
- Where only one instance of a resource type exists and no specific name adds clarity, use `main` as the label

```hcl
locals {
  resource_group_name = "rg-${var.environment}-${var.solution}"
  common_tags = {
    environment = var.environment
    solution    = var.solution
    owner       = var.owner
    costCenter  = var.cost_center
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

## Variables

Every variable must have `type` and `description`. Use `validation {}` for variables with a constrained set of allowed values:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment."
  validation {
    condition     = contains(["dev", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: dev, tst, uat, stg, prd."
  }
}
```

- Mark sensitive variables `sensitive = true`
- Provide default values for optional variables; omit defaults where a value must be explicitly set per environment
- Declare variables alphabetically

Standard variables every module should include: `cost_center`, `environment`, `location`, `owner`, `solution`.

## Outputs

- Declare outputs alphabetically
- Every output must have a `description`
- Mark sensitive outputs `sensitive = true`
- Scope outputs to what consuming modules actually need — do not expose every attribute

```hcl
output "resource_group_id" {
  description = "The ID of the resource group."
  value       = azurerm_resource_group.main.id
}
```

## Environment separation

Use one `.tfvars` file per environment in `environments/`, committed to Git. These files contain structural values only — never secrets:

```hcl
# environments/dev.tfvars
cost_center = "cc-1234"
environment = "dev"
location    = "norwayeast"
owner       = "platform-team"
solution    = "payments"
```

Run with: `terraform plan -var-file="environments/dev.tfvars"`

## Tags

Every resource that supports tags must receive at minimum:

| Tag | Source |
|---|---|
| `costCenter` | `var.cost_center` |
| `environment` | `var.environment` |
| `owner` | `var.owner` |
| `solution` | `var.solution` |

Build the tag map once in `locals.tf` and reference `local.common_tags` in every resource. `costCenter` and `owner` belong in tags only — they do not appear in resource names.

## Block ordering

Within each resource or module block, write arguments in this order:

1. Meta-arguments first: `count`, `for_each`, `provider`, `depends_on`
2. Resource-specific arguments
3. Nested blocks
4. `lifecycle` block last

## for_each vs count

Use `for_each` when creating multiple named instances. Use `count` only for conditional (0 or 1) creation:

```hcl
# ✅ GOOD — for_each for multiple named resources
resource "azurerm_resource_group" "rg" {
  for_each = toset(["network", "compute", "data"])
  name     = "rg-${var.environment}-${each.key}"
  location = var.location
}

# ✅ GOOD — count for conditional creation
resource "azurerm_monitor_metric_alert" "cpu" {
  count = var.enable_monitoring ? 1 : 0
  name  = "alert-cpu-${var.environment}"
}
```

## Remote state

Always configure a remote backend using Azure Storage. State must never be stored locally or committed to Git. State storage is provisioned separately from the module it tracks (via Bicep):

```hcl
terraform {
  required_version = ">= 1.5"
  backend "azurerm" {
    resource_group_name  = "rg-<env>-terraform-state"
    storage_account_name = "<state-storage-account>"
    container_name       = "tfstate"
    key                  = "<module>/terraform.tfstate"
  }
}
```

Commit `.terraform.lock.hcl` to Git — it pins provider versions for reproducible runs.

## Secrets and identity

Never put secrets, passwords, or keys in Terraform code or `.tfvars` files. Use Workload Identity and reference Azure Key Vault secrets at runtime:

```hcl
# ✅ GOOD — managed identity, no secret
resource "azurerm_kubernetes_cluster" "main" {
  identity {
    type = "SystemAssigned"
  }
}
```

Set `prevent_destroy = true` in the `lifecycle` block for critical resources (state storage, Key Vault).

## Provider selection

Use `azurerm` for all standard scenarios. Use `azapi` only when a resource is not yet supported in `azurerm`, or when you need a feature available only in the latest Azure API version. When using `azapi`, add a comment explaining why `azurerm` could not be used:

```hcl
# Using azapi: azurerm does not yet support <feature> as of provider v<version>
resource "azapi_resource" "example" { ... }
```

Do not introduce additional providers (`random`, `tls`, etc.) without documenting the reason in a comment.

## Idempotency

Write configurations that produce zero changes when applied a second time with the same inputs:

- Avoid `null_resource` and `local-exec` provisioners where a native resource exists
- Avoid scripts that run on every apply
- Use `lifecycle` settings or conditional expressions to handle external drift gracefully
- Prefer implicit dependencies (resource references) over explicit `depends_on`

## Pre-apply checklist

Run these before treating a module as ready:

```bash
terraform validate
terraform fmt -recursive
tflint --recursive
tfsec .
terraform plan -var-file="environments/dev.tfvars" -out=tfplan
```
