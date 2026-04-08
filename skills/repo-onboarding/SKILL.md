---
name: repo-onboarding
description: Repository onboarding guide. Use when you are new to the repository, want to understand how it works, or need to know the conventions, guardrails, and working agreements before making changes.
---

## When to use
- You are new to the repository
- You want to understand the repo structure, branching, or conventions
- You want to know the working agreements before making changes
- You have questions about guardrails (VPN, PIM, approval gates)

## Templates
- `../../standards/templates/knowledge-repo-onboarding.md` — discovery instructions and output format
- `../../standards/templates/repo-working-agreement.md` — branching, pipelines, VPN, PIM
- `../../standards/templates/repo-guardrails.md` — the 5 non-negotiable guardrails

Also read `README.md` <!-- and scan `.github/workflows/` and `solutions/` --> as instructed by `../../standards/templates/repo-onboarding.md`. 

## Constraints
- Do not expose template file names to the user
- Do not route to code review — that is the orchestrator's job
- After onboarding, close with: "Ready to make changes? Use `/code-reviewer` to review your code."