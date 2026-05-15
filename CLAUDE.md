# Claude Code Instructions

This file provides instructions for Claude Code contributing to this repository.
Whenever you make code changes, review if you need to update the relevant README.md files before committing. The root README.md covers repo overview; environment-specific details live in `docs/sandbox/README.md` and `docs/prod/README.md`.

## Terraform rules

### AVM module usage

AVM Resource Modules must be called directly from a solution's `main.tf`. Never wrap an AVM module inside a local module.

Local modules in `modules/` must be implemented using `azurerm`, `azapi`, or other provider resources directly — not by sourcing AVM modules internally.

Opinionated defaults (naming, purge protection, tags) belong in the solution's `locals.tf`, not in a wrapper module.

Reference: https://azure.github.io/Azure-Verified-Modules/usage/solution-development/terraform/


## Available Skills

Do NOT use the built-in Skill tool for these — they are not automatically registered there.

| Skill | Path | When to use |
|-------|------|-------------|
| `repo-code-reviewer` | `skills/code-reviewer/` | Review PowerShell, Bicep, or pipeline code against standards |
| `tf-architect` | `skills/tf-architect/` | Scaffold and generate Terraform modules for Azure infrastructure |
| `github-actions-cicd` | `skills/github-actions-cicd/` | Design, generate, and review GitHub Actions workflows for CI/CD |
| `naming-checker` | `skills/naming-checker/` | Check file, folder, or Azure resource naming conventions |
| `repo-onboarding` | `nimtech-intellectual-property/skills/repo-onboarding/` | Understand the repo structure, conventions, and working agreements |
| `tf-code-reviewer` | `skills/tf-code-reviewer/` | Review Terraform (.tf/.tfvars) code against team standards |

## Gotchas
- OIDC federation subject claims are environment-specific — see .github/docs/oidc.md
- AVM module upgrades may have breaking changes — check the changelog first
- When editing github actions, use the github-actions-cicd skill to ensure correct syntax and best practices

## Compaction
When compacting, preserve: modified .tf file paths, plan output summaries,
provider versions discussed, and any state operations performed.

