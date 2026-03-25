# Terraform Workspace — Claude Code Instructions

## Installed plugins

The following HashiCorp plugins are active in this session:

| Plugin | Purpose |
|--------|---------|
| `terraform-code-generation` | Generate `.tf` files for resources, providers, and backends |
| `terraform-module-generation` | Scaffold a full reusable module folder structure |

Invoke with a `/` slash command, e.g. `/terraform-code-generation Azure Storage Account with private endpoint`.

## Workspace structure

```
.
├── CLAUDE.md                        # This file
├── modules/                         # Custom reusable Terraform modules
├── standards/
│   └── templates/
│       ├── terraform-review.rules.md  # Terraform review rules (source of truth)
│       ├── code-review.rules.md       # Severity definitions and review principles
│       └── code-review.output.md      # Required output format for reviews
└── skills/
    ├── tf-architect/
    │   └── SKILL.md                # Plugin guide, AVM version checks, workflow
    └── tf-code-reviewer/
        ├── SKILL.md                # Review skill against team + HashiCorp standards
        └── tests/
            └── test-bad.tf             # Deliberately bad Terraform for testing the reviewer
```

## Standard workflows

### Generate and review new Terraform code

1. Use `/terraform-code-generation` or `/terraform-module-generation` to produce code.
2. Check all AVM module versions — any `version < 1.0.0` requires a custom module instead (see `skills/tf-architect/SKILL.md`).
3. Run `terraform fmt -recursive && terraform validate && tfsec .`.
4. Invoke the `tf-code-reviewer` skill to review before committing.

### Review existing code

Ask: _"Review this Terraform file/diff"_ — the `tf-code-reviewer` skill will apply rules from `standards/templates/`.

### AVM module version rule (enforced)

| Version | Action |
|---------|--------|
| Unpinned | **BLOCKER** — pin immediately |
| `0.0.x` | **BLOCKER** — build custom module |
| `0.x.x` | **MAJOR** — build custom module |
| `>= 1.0.0` | OK to use directly |

## Team conventions (Nimtech)

- Resource names: `{type}-{env}{solution}`
- Required tags: `environment`, `solution`, `owner`, `costCenter`
- Remote state: Azure Storage Account, provisioned via Bicep — never local
- Separate state per environment (`can/` canary, `liv/` live)
- No secrets in Terraform — Workload Identity + Key Vault references only
- AVM preferred for AKS, Key Vault, networking, and identity resources
