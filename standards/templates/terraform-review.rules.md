# Terraform Review Standards

This document combines **HashiCorp's official Terraform style guide** with **team-specific patterns**. Both sets of standards apply to all reviews. Where team patterns add requirements beyond HashiCorp defaults (tagging, state, naming), apply both — the team patterns are additive, not contradictory.

---

## Pre-review commands

Run these before starting a review:

```bash
# Format check (use -recursive for modules)
terraform fmt -recursive

# Validate syntax
terraform validate

# Security scan
tfsec .

# Full pre-review workflow
terraform fmt -recursive && terraform validate && tfsec .

# Plan (always review output before apply)
terraform plan -out=tfplan
```

## Pre-review checklist

- [ ] `terraform fmt -recursive` shows no diff
- [ ] `terraform validate` passes with no errors
- [ ] `tfsec` run — findings reviewed
- [ ] `tflint` run with azurerm ruleset
- [ ] `.terraform.lock.hcl` committed to Git
- [ ] No `terraform.tfstate` committed to Git
- [ ] Required providers specified with version constraints
- [ ] All variables have descriptions and types
- [ ] No hardcoded secrets or credentials
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] Remote state backend configured

---

## File organisation

> See [terraform-standards.md](terraform-standards.md) — Module structure.

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

### Block internal ordering

Within any `resource`, `data`, or `module` block, order arguments as follows:

1. **Top meta-arguments** (in this order): `provider`, `count`, `for_each`
2. **Required arguments** (alphabetical)
3. **Optional arguments** (alphabetical)
4. **Required nested blocks**
5. **Optional nested blocks**
6. **Bottom meta-arguments**: `depends_on`, `lifecycle`

Within `lifecycle`: `create_before_destroy`, `ignore_changes`, `prevent_destroy`.

Separate each group with a blank line.

```hcl
# Good
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

  # meta (bottom)
  lifecycle {
    prevent_destroy = true
  }
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

## Naming conventions

### Terraform symbolic names (HashiCorp standard)

Applies to: resource labels, data source labels, module labels, variables, outputs, locals.

- MUST use `lower_snake_case`.
- MUST be **descriptive nouns** that exclude the resource type.
- MUST be singular, not plural.
- Use `main` when only one instance exists and a more specific name adds no value.

```hcl
# Bad
resource "azurerm_resource_group" "myRG-azure" {}
resource "azurerm_storage_account" "storage_accounts" {}

# Good
resource "azurerm_resource_group" "main" {}
resource "azurerm_storage_account" "app_data" {}
```

### Azure resource names

> See [naming-conventions.md](naming-conventions.md) — Azure Resource Names.

Names MUST be parameterised via locals — never hardcoded strings in a resource block.

---

## Variables

> See [terraform-standards.md](terraform-standards.md) — Variable quality, for type, description, sensitive, and validation basics.

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

---

## Outputs

- All outputs MUST have `description`.
- Sensitive outputs MUST have `sensitive = true`.
- Outputs SHOULD use the **anti-corruption layer pattern** — output discrete computed attributes, not entire resource objects.
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

## Resource creation patterns

### `for_each` vs `count`

- Prefer `for_each` over `count` for multiple named resources — avoids index-based addressing and destructive plan changes.
- `for_each` collections MUST be `map(xxx)` or `set(xxx)` with **static literal keys**.
- Use `count` only for conditional single-resource creation.

```hcl
# Bad — count for named resources
resource "azurerm_subnet" "app" {
  count = 3
  name  = "subnet-${count.index}"
}

# Good — for_each with a map
resource "azurerm_subnet" "app" {
  for_each = var.subnet_map
  name     = each.key
}

# Good — count for conditional creation
resource "azurerm_monitor_metric_alert" "cpu" {
  count = var.alerts_enabled ? 1 : 0
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

For optional object variables, use `object({...})` with `default = null` to avoid "known after apply" issues:

```hcl
variable "private_endpoint" {
  type = object({
    subnet_id = string
  })
  default = null
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

All providers in `required_providers` MUST specify both `source` and `version` with minimum AND maximum major version constraints. Use `~> #.#` (pessimistic operator).

Azure providers and their supported ranges:

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

### Dependency lock file

`.terraform.lock.hcl` MUST be committed to Git. Never commit `terraform.tfstate`, `terraform.tfstate.backup`, or `.terraform/`.

---

## AVM (Azure Verified Modules)

Prefer AVM modules over custom implementations for standard Azure resources. Flag if a custom module reimplements something AVM already covers.

> See [terraform-standards.md](terraform-standards.md) — AVM version checks, for version pinning severity levels.

AVM modules MUST be referenced via the Terraform registry — never via git references:

```hcl
# Bad — unpinned
module "storage" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"
}

# Bad — git reference
module "storage" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount"
}

# Good
module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6"
}
```

### AVM module block ordering

Within AVM module blocks, use this order:

1. `source`, `version`, `count`, `for_each`
2. Required arguments (alphabetical)
3. Optional arguments (alphabetical)
4. `depends_on`, `providers`

---

## Module structure

Every module MUST be self-contained with at minimum: `terraform.tf`, `main.tf`, `variables.tf`, `outputs.tf`. Add `locals.tf` when locals are used.

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

## State management

> See [terraform-standards.md](terraform-standards.md) — State management.

---

## Security

> See [terraform-standards.md](terraform-standards.md) — Security.

---

## Code quality

> See [terraform-standards.md](terraform-standards.md) — Code quality and for_each vs count.

---

## Testing

Test files use `.tftest.hcl` extension and live in a `tests/` directory.

- **Plan-mode tests** validate logic without creating infrastructure (faster, safe for CI on every PR).
- **Apply-mode tests** create real infrastructure and validate computed attributes (run on schedule or pre-release).

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

Required tooling: `terraform validate`, `terraform fmt`, `tflint` (azurerm ruleset), `tfsec`/`checkov`.

---

## Team patterns (Nimtech)

Flag deviations from these patterns:

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
