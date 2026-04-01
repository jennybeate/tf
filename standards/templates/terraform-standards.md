# Terraform Review Standards

## Pre-review commands

Run these before starting a review:

```bash
# Validate syntax
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
- [ ] Required providers specified with version constraints
- [ ] All variables have descriptions and types
- [ ] No hardcoded secrets or credentials
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] Remote state backend configured
- [ ] Resource names follow naming convention
- [ ] Tags applied consistently
- [ ] Unused variables and resources removed

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

## AVM version checks

- **[BLOCKER]** AVM module has no version pinned — a floating reference will silently pull in breaking changes on the next run.
- **[MAJOR]** AVM module is on a `0.0.x` version in production — these are high-churn pre-release builds with no stability guarantees.
- **[MINOR]** AVM module is on a `0.x.x` version in production with no documented acceptance of pre-release risk — flag for awareness.

```hcl
# ❌ BAD — unpinned
module "aks" {
  source = "Azure/avm-res-containerservice-managedcluster/azurerm"
}

# ⚠️ CAUTION — pre-release in prod
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.0.3"
}

# ✅ GOOD — pinned, stable minor version
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.3.0"
}
```

## State management

- Is remote state configured? (Azure Storage Account, not local)
- Is state storage provisioned separately from the module it tracks? (e.g. via Bicep)
- Are separate state files used per environment (canary/live)?
- Flag any `terraform.tfstate` or `terraform.tfstate.backup` files committed to Git.
- Is `.terraform.lock.hcl` committed to Git? (It must be — it pins provider versions for reproducible runs.)
- Is state locking enabled? Azure Storage backends lock state automatically via blob leases. Never pass `-lock=false` except in a documented break-glass scenario.
- Is `-lock-timeout` set on plan and apply commands? In CI, parallel runs on the same state file can race; a non-zero timeout (e.g. `5m`) lets a job wait for the lease to clear rather than fail immediately.

```hcl
# ❌ BAD — local state
# No backend block defined

# ✅ GOOD — remote state in Azure Storage
terraform {
  required_version = ">= 1.5"
  backend "azurerm" {
    resource_group_name  = "rg-<env>-<costcenter>-terraform-state"
    storage_account_name = "<state-storage-account>"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }
}
```

## Variable quality

- Do all variables have descriptions and explicit types?
- Do sensitive variables use `sensitive = true`?
- Are default values provided where sensible — and omitted where a value must be explicitly set per environment?
- Is `validation {}` used for variables with constrained allowed values?
- Are unused variables removed?

```hcl
# ❌ BAD
variable "env" {}

# ✅ GOOD
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "tst", "uat", "stg", "prd"], var.environment)
    error_message = "Must be one of: dev, tst, uat, stg, prd."
  }
}
```

## Security

- No hardcoded secrets, passwords, or keys — flag immediately as **[BLOCKER]**.
- Are managed identities used instead of service principal secrets where possible?
- Are role assignments scoped to the minimum required scope (resource, not subscription)? - with the exception of Landing Zone provisioning.
- Is `prevent_destroy = true` set on critical resources (state storage, Key Vault)?
- Are sensitive outputs marked `sensitive = true`?

```hcl
# ❌ BAD — hardcoded secret
resource "azurerm_kubernetes_cluster" "aks" {
  client_secret = "supersecret123"
}

# ✅ GOOD — managed identity, no secret
resource "azurerm_kubernetes_cluster" "aks" {
  identity {
    type = "SystemAssigned"
  }
}
```

## Block ordering

Within each resource or module block, arguments must appear in this order:

1. **Meta-arguments** first: `count`, `for_each`, `provider`, `depends_on`
2. **Arguments** (resource-specific attributes)
3. **Nested blocks**
4. **`lifecycle`** block last

```hcl
# ❌ BAD — lifecycle before arguments, depends_on buried
resource "azurerm_resource_group" "main" {
  lifecycle {
    prevent_destroy = true
  }
  name     = local.resource_group_name
  location = var.location
  depends_on = [azurerm_something.other]
}

# ✅ GOOD — meta-arguments → arguments → lifecycle
resource "azurerm_resource_group" "main" {
  depends_on = [azurerm_something.other]

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
```

## Naming and tagging

For Azure resource naming patterns and examples, see [`naming-conventions.md`](naming-conventions.md) — it is the source of truth for all naming rules.

Terraform-specific label rules (these apply to HCL identifiers only, not Azure resource names):

- Resource labels must be lowercase with underscores (e.g. `resource "azurerm_resource_group" "my_rg"`) — no hyphens, no camelCase.
- Resource labels must be **singular**, not plural (`web_server`, not `web_servers`).
- Where only one instance exists and no specific name adds clarity, use `main` as the label.

Additional checks:

- Are Azure resource names constructed in `locals.tf` via a local — never hardcoded in the resource block?
- Are tags applied consistently — at minimum: `environment`, `solution`, `owner`, `costCenter`?
- Do `costCenter` and `owner` appear in **tags only**, not in resource names?

```hcl
# ❌ BAD
resource "azurerm_resource_group" "rg" {
  name = "my-resource-group"
}

# ✅ GOOD
locals {
  resource_group_name = "rg-${var.environment}-${var.solution}-k8s"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

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
environment         = "dev"
solution            = "payments"
owner               = "platform-team"
cost_center         = "cc-1234"
location            = "norwayeast"
resource_group_name = "rg-dev-payments"
```

Run with: `terraform plan -var-file="environments/dev.tfvars"`

- [BLOCKER] Secrets in any `.tfvars` file committed to Git.
- [MAJOR] No environment separation — a single `terraform.tfvars` shared across environments.

## Code quality

- Is `for_each` or `count` used to avoid copy-paste of similar resources?
- Are `depends_on` overrides minimal — prefer implicit dependencies via resource references?
- Are `null_resource` and `local-exec` provisioners avoided where a native resource exists?
- Are resource dependencies optimised for parallel execution where possible?

### for_each vs count

Use `for_each` when creating multiple named instances; use `count` only for conditional (0 or 1) creation:

```hcl
# ❌ BAD — count for multiple named resources (index-based, fragile)
resource "azurerm_resource_group" "rg" {
  count    = 3
  name     = "rg-${count.index}"
  location = var.location
}

# ✅ GOOD — for_each with meaningful keys
resource "azurerm_resource_group" "rg" {
  for_each = toset(["network", "compute", "data"])
  name     = "rg-${var.environment}-${each.key}"
  location = var.location
}

# ✅ GOOD — count for conditional creation
resource "azurerm_monitor_metric_alert" "cpu" {
  count = var.enable_monitoring ? 1 : 0
  name  = "alert-cpu-${var.environment}"
  # ...
}
```

## Output hygiene

- Are outputs described?
- Are sensitive outputs marked `sensitive = true`?
- Are outputs scoped to what consuming modules actually need — not dumping everything?

## Provider selection

- **[MAJOR]** `azapi` is used for a resource that `azurerm` already supports — prefer `azurerm` for stability and coverage.
- **[NIT]** `azapi` usage has no comment explaining why `azurerm` could not be used — document the reason inline.
- **[MINOR]** An additional provider (`random`, `tls`, etc.) is introduced without a comment explaining why — document the reason inline.

## Nimtech patterns

Flag deviations from these established patterns:

- **AVM preferred** for AKS, Key Vault, networking, and identity resources.
- **Remote state in Azure Storage** provisioned via Bicep (`stateStorage/main.bicep`).
- **Canary/live split** via separate parameter files (`config/parameters/can/` and `liv/`).
- **No secrets in Terraform** — Workload Identity and Key Vault references only.
- **Azure DevOps pipelines** with Plan→Apply stages and change detection.

## References

- [HashiCorp Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [tfsec](https://aquasecurity.github.io/tfsec/)
- [Azure CAF Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
