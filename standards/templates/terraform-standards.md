# Terraform Review Standards

This document is the single source of truth for Terraform authoring and review at Nimtech. It combines **HashiCorp's official Terraform style guide** with **team-specific patterns**. Both sets of standards apply. Where team patterns add requirements beyond HashiCorp defaults (tagging, state, naming), apply both — the team patterns are additive, not contradictory.

For review checks and what will be flagged, this file is authoritative. For generative work (scaffolding new modules), see `terraform-authoring-guide.md`.

## Pre-review commands

Run these before starting a review:

```bash
# Validate syntax
terraform init -backend=false
terraform validate

# Format check (use -recursive for modules)
terraform fmt -recursive

# Lint (best practices + provider-specific rules)
tflint --recursive

# Security scan
tfsec .

# Full pre-review workflow
terraform validate && terraform fmt -recursive && tflint --recursive && tfsec .

# Plan (always review output before apply)
terraform plan -out=tfplan
```

## Pre-review checklist

- [ ] `terraform validate` passes with no errors
- [ ] `terraform fmt` shows no diff
- [ ] `tflint` run — findings reviewed
- [ ] `tfsec` run — findings reviewed
- [ ] No `terraform.tfstate` committed to Git
- [ ] `.terraform.lock.hcl` committed to Git
- [ ] Required providers specified with version constraints
- [ ] All variables have descriptions and types
- [ ] No hardcoded secrets or credentials
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] Remote state backend configured
- [ ] Resource names follow naming convention
- [ ] Tags applied consistently
- [ ] Unused variables and resources removed

---

## Formatting

### Indentation and alignment

- **Two spaces** per nesting level — no tabs.
- Align `=` signs for consecutive single-line arguments in the same block.

```hcl
# Good
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

### `ignore_changes` syntax

`ignore_changes` MUST NOT use quoted strings.

```hcl
# Bad
lifecycle {
  ignore_changes = ["tags"]
}

# Good
lifecycle {
  ignore_changes = [tags]
}
```

---

## Module structure

Standard file layout (HashiCorp convention):

| File | Purpose |
|---|---|
| `terraform.tf` | Terraform version and required providers (`versions.tf` is an acceptable alias) |
| `providers.tf` | Provider configurations |
| `main.tf` | Primary resources and data sources |
| `variables.tf` | Input variable declarations (alphabetical) |
| `outputs.tf` | Output value declarations (alphabetical) |
| `locals.tf` | Local value declarations |

- Is the module self-contained with `main.tf`, `variables.tf`, `outputs.tf`?
- Are locals used to avoid repetition (`locals.tf`)?
- Is there a `terraform.tf` (or `versions.tf`) with explicit provider and Terraform version constraints?
- Are large configurations split across logical files (e.g. `network.tf`, `identity.tf`, `aks.tf`)?
- Prefer **Azure Verified Modules (AVM)** over custom modules for standard Azure resources — flag if a custom module reimplements something AVM already covers.

### Breaking change controls

New resources added in minor/patch versions MUST have a feature toggle defaulting to `false`:

```hcl
variable "route_table_enabled" {
  type     = bool
  default  = false
  nullable = false
}

resource "azurerm_route_table" "main" {
  count = var.route_table_enabled ? 1 : 0
}
```

When renaming resources, include a `moved {}` block to prevent destructive plan changes.

---

## AVM version checks

- **[BLOCKER]** AVM module has no version pinned — a floating reference will silently pull in breaking changes on the next run.
- **[MAJOR]** AVM module is on a `0.0.x` version in production — these are high-churn pre-release builds with no stability guarantees.
- **[MINOR]** AVM module is on a `0.x.x` version in production with no documented acceptance of pre-release risk — flag for awareness.

AVM modules MUST be referenced via the Terraform registry — never via git references:

```hcl
# Bad — unpinned
module "key_vault" {
  source = "Azure/avm-res-keyvault-vault/azurerm"
}

# Bad — git reference
module "key_vault" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault"
}

# Good — pinned stable version
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"
}
```

### AVM module block ordering

Within AVM module blocks, use this order:

1. `source`, `version`, `count`, `for_each`
2. Required arguments (alphabetical)
3. Optional arguments (alphabetical)
4. `depends_on`, `providers`

---

## State management

- Is remote state configured? (Azure Storage Account, not local)
- Is state storage provisioned separately from the module it tracks? (e.g. via Bicep)
- Are separate state files used per environment (canary/live)?
- Flag any `terraform.tfstate` or `terraform.tfstate.backup` files committed to Git.
- Is `.terraform.lock.hcl` committed to Git? (It must be — it pins provider versions for reproducible runs.)
- Is state locking enabled? Azure Storage backends lock state automatically via blob leases. Never pass `-lock=false` except in a documented break-glass scenario.
- Is `-lock-timeout` set on plan and apply commands? In CI, parallel runs on the same state file can race; a non-zero timeout (e.g. `5m`) lets a job wait for the lease to clear rather than fail immediately.

```hcl
# Bad — local state
# No backend block defined

# Good — remote state in Azure Storage
terraform {
  required_version = "~> 1.9"
  backend "azurerm" {
    resource_group_name  = "rg-<env>-<costcenter>-terraform-state"
    storage_account_name = "<state-storage-account>"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }
}
```

---

## Version constraints

### Terraform version

`terraform.tf` MUST declare `required_version` using `~>` or a range:

```hcl
terraform {
  required_version = "~> 1.9"
}
```

### Provider versions

All providers in `required_providers` MUST specify both `source` and `version` with `~> #.#` (pessimistic operator). Azure providers and their supported constraints:

| Provider | Required constraint |
|---|---|
| `hashicorp/azurerm` | `~> 4.0` |
| `Azure/azapi` | `~> 2.0` |

```hcl
terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

`provider {}` blocks MUST NOT be declared inside modules (except `alias` for `configuration_aliases`). Provider configuration is passed in by the calling root module.

---

## Variable quality

- Do all variables have descriptions and explicit types?
- Do sensitive variables use `sensitive = true`?
- Are default values provided where sensible — and omitted where a value must be explicitly set per environment?
- Is `validation {}` used for variables with constrained allowed values?
- Are unused variables removed?

Additional rules:

- **Order**: required variables first (alphabetical), then optional (alphabetical).
- `type` MUST be as precise as possible — avoid `any`.
- Use `bool` instead of `string` for true/false values.
- Use concrete `object({...})` instead of `map(any)`.
- Collections (`list`, `set`, `map`) SHOULD have `nullable = false`.
- `nullable = true` MUST be avoided unless null carries specific semantic meaning.
- `sensitive = false` MUST NOT be declared (it is the default).
- Sensitive variables MUST NOT have default values.
- Feature toggle variables MUST use positive names (`xxx_enabled`, not `xxx_disabled`).
- Do NOT add `enabled` or `module_depends_on` variables to control the entire module.

```hcl
# Bad
variable "env" {}

# Good
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["can", "liv", "dev", "sbx", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: can, liv, dev, sbx, tst, uat, stg, prd."
  }
}
```

---

## Locals

- All locals MUST be arranged **alphabetically** within each `locals {}` block.
- `locals.tf` SHOULD only contain `locals {}` blocks.
- Use `coalesce()` or `try()` instead of ternary null checks.

```hcl
# Bad
local.name == null ? "${var.prefix}-default" : local.name

# Good
coalesce(local.name, "${var.prefix}-default")
```

---

## Security

- No hardcoded secrets, passwords, or keys — flag immediately as **[BLOCKER]**.
- Are managed identities used instead of service principal secrets where possible?
- Are role assignments scoped to the minimum required scope (resource, not subscription)? — with the exception of Landing Zone provisioning.
- Is `prevent_destroy = true` set on critical resources (state storage, Key Vault)?
- Are sensitive outputs marked `sensitive = true`?

```hcl
# Bad — hardcoded secret
resource "azurerm_kubernetes_cluster" "aks" {
  client_secret = "supersecret123"
}

# Good — managed identity, no secret
resource "azurerm_kubernetes_cluster" "aks" {
  identity {
    type = "SystemAssigned"
  }
}
```

---

## Block ordering

Within each resource or module block, arguments must appear in this order:

1. **Meta-arguments** first (in this order): `provider`, `count`, `for_each`
2. **Required arguments** (alphabetical)
3. **Optional arguments** (alphabetical)
4. **Required nested blocks**
5. **Optional nested blocks**
6. **Bottom meta-arguments**: `depends_on`, `lifecycle`

Within `lifecycle`: `create_before_destroy`, `ignore_changes`, `prevent_destroy`.

Separate each group with a blank line.

```hcl
# Bad — lifecycle before arguments
resource "azurerm_resource_group" "main" {
  lifecycle {
    prevent_destroy = true
  }
  name     = local.resource_group_name
  location = var.location
}

# Good — meta-arguments → required args → optional args → lifecycle
resource "azurerm_storage_account" "main" {
  # meta
  for_each = var.storage_accounts

  # required arguments
  account_replication_type = each.value.replication_type
  account_tier             = each.value.tier
  location                 = var.location
  name                     = each.key
  resource_group_name      = var.resource_group_name

  # optional arguments
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  lifecycle {
    prevent_destroy = true
  }
}
```

---

## Naming and tagging

For Azure resource naming patterns and examples, see [`naming-conventions.md`](naming-conventions.md) — it is the source of truth for all naming rules.

Terraform-specific label rules (apply to HCL identifiers only, not Azure resource names):

- Resource labels MUST use `lower_snake_case` — no hyphens, no camelCase.
- Resource labels MUST be **singular**, not plural (`web_server`, not `web_servers`).
- Labels MUST be descriptive nouns that exclude the resource type.
- Where only one instance exists and no specific name adds clarity, use `main` as the label.

Additional checks:

- Are Azure resource names constructed in `locals.tf` via a local — never hardcoded in the resource block?
- Are tags applied consistently — at minimum: `environment`, `solution`, `owner`, `costCenter`?
- Do `costCenter` and `owner` appear in **tags only**, not in resource names?

```hcl
# Bad
resource "azurerm_resource_group" "rg" {
  name = "my-resource-group"
}

# Good
locals {
  resource_group_name = "rg-${var.environment}-${var.solution}"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

---

## Environment separation

Use one `terraform.tfvars` file per environment, committed to Git. These files contain only structural values — never secrets.

```text
environments/
  dev.tfvars
  stg.tfvars
  prd.tfvars
```

```hcl
# environments/dev.tfvars
environment = "dev"
solution    = "payments"
owner       = "platform-team"
cost_center = "cc-1234"
location    = "norwayeast"
```

Run with: `terraform plan -var-file="environments/dev.tfvars"`

- **[BLOCKER]** Secrets in any `.tfvars` file committed to Git.
- **[MAJOR]** No environment separation — a single `terraform.tfvars` shared across environments.

---

## Code quality

- Is `for_each` or `count` used to avoid copy-paste of similar resources?
- Are `depends_on` overrides minimal — prefer implicit dependencies via resource references?
- Are `null_resource` and `local-exec` provisioners avoided where a native resource exists?
- Are resource dependencies optimised for parallel execution where possible?

### `for_each` vs `count`

Use `for_each` when creating multiple named instances; use `count` only for conditional (0 or 1) creation. `for_each` collections MUST be `map(xxx)` or `set(xxx)` with static literal keys.

```hcl
# Bad — count for multiple named resources (index-based, fragile)
resource "azurerm_subnet" "app" {
  count = 3
  name  = "subnet-${count.index}"
}

# Good — for_each with meaningful keys
resource "azurerm_subnet" "app" {
  for_each = var.subnet_map
  name     = each.key
}

# Good — count for conditional creation
resource "azurerm_monitor_metric_alert" "cpu" {
  count = var.enable_monitoring ? 1 : 0
}
```

### Dynamic blocks for optional nested objects

Conditional nested blocks MUST use `dynamic`:

```hcl
dynamic "identity" {
  for_each = var.identity != null ? [var.identity] : []

  content {
    type         = identity.value.type
    identity_ids = identity.value.identity_ids
  }
}
```

### Null-safe optional objects

For optional object variables, use `object({...})` with `default = null`:

```hcl
variable "private_endpoint" {
  type = object({
    subnet_id = string
  })
  default = null
}
```

---

## Output hygiene

- Are outputs described?
- Are sensitive outputs marked `sensitive = true`?
- Are outputs scoped to what consuming modules actually need — not dumping everything?
- Use the **anti-corruption layer pattern** — output discrete computed attributes, not entire resource objects.
- Do NOT output values that are already inputs (except `name`).

```hcl
# Bad — exposes entire object; schema can change with provider updates
output "storage_account" {
  value = azurerm_storage_account.main
}

# Good — discrete, stable attributes
output "primary_blob_endpoint" {
  description = "Primary blob service endpoint URL."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}
```

---

## Provider selection

- **[MAJOR]** `azapi` is used for a resource that `azurerm` already supports — prefer `azurerm` for stability and coverage.
- **[NIT]** `azapi` usage has no comment explaining why `azurerm` could not be used — document the reason inline.
- **[MINOR]** An additional provider (`random`, `tls`, etc.) is introduced without a comment explaining why — document the reason inline.

---

## Testing

Test files use the `.tftest.hcl` extension and live in a `tests/` directory.

- **Plan-mode tests** validate logic without creating infrastructure — faster, safe for CI on every PR.
- **Apply-mode tests** create real infrastructure and validate computed attributes — run on schedule or pre-release.

```hcl
# tests/validation.tftest.hcl
run "validates_environment_variable" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [var.environment]
}
```

Required tooling: `terraform validate`, `terraform fmt`, `tflint` (azurerm ruleset), `tfsec`.

---

## Nimtech patterns

Flag deviations from these established patterns:

- **AVM preferred** for AKS, Key Vault, networking, and identity resources.
- **Remote state in Azure Storage** provisioned via Bicep (`stateStorage/main.bicep`).
- **Canary/live split** via separate parameter files (`config/parameters/can/` and `liv/`).
- **No secrets in Terraform** — Workload Identity and Key Vault references only.
- **Azure DevOps pipelines** with Plan→Apply stages and change detection.

---

## References

- [HashiCorp Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Terraform Requirements](https://azure.github.io/Azure-Verified-Modules/specs/terraform/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [tfsec](https://aquasecurity.github.io/tfsec/)
- [Azure CAF Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
