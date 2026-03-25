---
name: tf-architect
description: "Terraform architecture and code generation skill. Use when: designing Azure infrastructure with Terraform, generating Terraform code, using the terraform-code-generation plugin, using the terraform-module-generation plugin, selecting AVM modules, checking if an AVM module is production-ready, scaffolding a new module, deciding between custom module and AVM module, AVM version below 1, pre-release module warning."
argument-hint: "Describe the Azure infrastructure you want to build, or the AVM module you are evaluating"
---

# Terraform Architect

## When to Use

- You want to generate Terraform code for Azure resources
- You need to scaffold a new reusable Terraform module
- You are evaluating an AVM module and want to know if it is production-ready
- You want to know which HashiCorp plugin to use (`terraform-code-generation` vs `terraform-module-generation`)
- A generated module block references an AVM module version — always check it before accepting

---

## Plugin Guide

The following HashiCorp plugins are available in the **Claude Code CLI** after running:

```
claude plugin install terraform-code-generation@hashicorp
claude plugin install terraform-module-generation@hashicorp
```

Invoke them with a `/` slash command inside a `claude` session, or describe your intent in chat and the agent will trigger the appropriate plugin.

### `terraform-code-generation`

**Use when you need** `.tf` files for one or more resources, provider/backend config, or a complete working configuration for a defined use-case.

| Example prompts |
|----------------|
| `/terraform-code-generation Azure Storage Account with private endpoint and CMK` |
| `/terraform-code-generation azurerm backend config for tfstate in West Europe` |
| `/terraform-code-generation AKS cluster with system-assigned identity` |

**Output:** `main.tf`, `variables.tf`, `outputs.tf`, provider/backend blocks as needed.

---

### `terraform-module-generation`

**Use when you need** a full reusable module scaffold — the complete folder structure with all standard files.

| Example prompts |
|----------------|
| `/terraform-module-generation create a module for Azure Container Registry` |
| `/terraform-module-generation scaffold a network module with VNet and subnets` |
| `/terraform-module-generation reusable AKS module with configurable node pools` |

**Output:** Full module folder with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.

---

## Choosing Between the Two Plugins

| Situation | Use |
|-----------|-----|
| Need a single resource or a composition of resources for one deployment | `terraform-code-generation` |
| Building something that will be called from multiple environments or root modules | `terraform-module-generation` |
| AVM module exists but version < 1.0.0 (see below) | `terraform-module-generation` to build a custom replacement |

---

## AVM Module Version Check

> ⚠️ **Always verify AVM module versions before accepting generated code.**

When any module block references an AVM source (`Azure/avm-*`), check the `version` field and apply these rules:

| Version | Status | Required action |
|---------|--------|-----------------|
| No `version` pinned | ❌ **BLOCKER** | Pin an explicit version immediately — floating references silently pull in breaking changes |
| `0.0.x` | ❌ **BLOCKER** | High-churn pre-release — **create a custom module** |
| `0.x.x` (non-zero minor) | ⚠️ **MAJOR** | Pre-release with no stability guarantee — **create a custom module** |
| `>= 1.0.0` | ✅ **OK** | Production-ready, safe to use |

### Warning Message — AVM Module Below Version 1.0

Whenever a plugin generates or suggests an AVM module with a version below `1.0.0`, surface this warning:

---

> ⚠️ **Pre-release AVM module detected**
>
> The module **`<module-name>`** is at version **`<version>`** (< 1.0.0). Pre-release AVM modules carry **no stability guarantees** — interfaces, variable names, and defaults may change between patch releases without notice.
>
> **We will need to create a custom module instead.**
> Use the `terraform-module-generation` plugin to scaffold it.
> Reference the AVM module's [variable interface](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/) as a guide for your own implementation, but do not depend on the module directly.

---

Check the current production status of any AVM module at:
- [AVM Resource Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
- [AVM Pattern Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-pattern-modules/)

---

## Recommended Workflow

1. **Define the goal** — describe the Azure resource or infrastructure pattern you need.

2. **Check AVM availability**
   - Search the [AVM Resource Modules index](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
   - If found AND version ≥ `1.0.0` → use it directly with `terraform-code-generation`
   - If found AND version < `1.0.0` → scaffold a custom module with `terraform-module-generation`
   - If not found → scaffold a custom module with `terraform-module-generation`

3. **Generate the code** using the appropriate plugin command.

4. **Apply team standards** — all generated code must conform to [`../../standards/templates/terraform-review.rules.md`](../../standards/templates/terraform-review.rules.md).

5. **Review** — use the `tf-code-reviewer` skill to run a full review against team standards before committing.
