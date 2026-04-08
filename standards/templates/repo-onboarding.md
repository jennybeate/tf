# Onboarding Guide (Discovery Template)

## Contents

- [Discovery Instructions](#discovery-instructions)
  - [1. Discover Repository Purpose](#1-discover-repository-purpose)
  - [2. Identify Key Features/Components](#2-identify-key-featurescomponents)
  - [3. Understand Environments and Deployment Flow](#3-understand-environments-and-deployment-flow)
  - [4. Identify Technology Stack](#4-identify-technology-stack)
- [Output Format](#output-format)
  - [Repository Overview](#repository-overview)
  - [How Work Flows Here](#how-work-flows-here)
  - [Start Working](#start-working)
  - [What to Do Next](#what-to-do-next)
- [Fallback Content](#fallback-content)
  - [Minimal Repository Overview](#minimal-repository-overview)
  - [Minimal Getting Started](#minimal-getting-started)
- [Notes for Agent](#notes-for-agent)

---

This template guides the agent to dynamically discover and present repository information.

## Discovery Instructions

When a user asks about the repository or requests onboarding, follow these steps:

### 1. Discover Repository Purpose
**Sources to check:**
- `README.md` (root) - First 50 lines for overview
- `.github/README.md` - Alternative location
- `docs/*/index.md` - Documentation index files (if present)

**Extract:**
- Primary purpose (1-2 sentences)
- Target audience (who uses this repo)
- What problems it solves

### 2. Identify Key Features/Components
**Sources to check: (Example. Update paths to suit your repository structure)**
- `README.md` - Look for sections like "Features", "What's Included", "Components"
- Directory structure - Top-level directories indicate capabilities
- `.github/workflows/` - Workflow file names reveal solutions (e.g., `canary-namespaceVending.yml`)
- `solutions/` subdirectories - Each folder represents a solution
- `shared/pipeline-scripts/` - Shared utilities used by all solutions
- `docs/platform-services/` - Service documentation folders 

**Extract:**
- 3-5 main features or solutions (bulleted list)
- Keep descriptions short (3-5 words each)

### 3. Understand Environments and Deployment Flow
**Sources to check:**
- `.github/workflows/` - Presence of `canary-*`, `live-*`, `template-*` patterns
- `.canary.env` and `.env` files - Indicates multi-environment setup (or equivalent)
- `repo-working-agreement.md` - CI/CD and environment flow section

**Extract:**
- Environment names (e.g., canary, live, production)
- Branch-to-environment mapping
- Deployment triggers (PR, main branch, manual)

### 4. Identify Technology Stack
**Sources to check:**
- File extensions in repository (e.g `.ps1`, `.bicep`, `.yml`, `.py`, etc.)
- `package.json`, `requirements.txt`, `pom.xml` - Dependency files
- `.devcontainer/devcontainer.json` - Development tools

**Extract:**
- Primary languages (e.g., PowerShell, Bicep, Python)
- Key frameworks or tools (e.g., GitHub Actions, Terraform, Azure CLI)

---

## Output Format

Present discovered information in this structure:

### Repository Overview

**Purpose**
[1-2 sentence summary of what this repository does]

**Key Features**
- [Feature 1 name] - [Brief description]
- [Feature 2 name] - [Brief description]
- [Feature 3 name] - [Brief description]

**Technology Stack**
[List primary languages and tools]

---

### How Work Flows Here

**Environments**
[Describe environments: names, purposes, and access levels]

**Deployment Flow**
- [Branch pattern] → [Environment] → [Trigger type]
- [Branch pattern] → [Environment] → [Trigger type]

**Key Directories**
- `[directory/]` - [Purpose]
- `[directory/]` - [Purpose]

---

### Start Working

**Always** start by telling the user to create a branch from `main`:

```
git checkout main && git pull
git checkout -b feat/<short-description>   # For new features
git checkout -b fix/<short-description>    # For bug fixes
```

Explain that all work happens in short-lived branches. The branch name determines what happens:
- `feat/*` and `fix/*` branches automatically deploy to **canary** on push
- Only `main` deploys to **live** after a PR process

### What to Do Next

Once the user has a branch, suggest how Copilot can help:

- **"Review my code"** — Runs a  Code Reviewer with severity-based findings
- **"Check security of this file"** — Validates against repository guardrails
- **"Check naming conventions"** — Validates file and variable naming standards
- **"How do we branch and merge?"** — Explains the branching model and PR process

---

## Fallback Content

If discovery fails or sources are missing, use these generic guidelines:

### Minimal Repository Overview
- This repository contains [infer from directory names]
- Primary technology: [infer from file extensions]
- Follows standard Git workflow with pull request reviews

### Minimal Getting Started
- Clone the repository
- Review README.md for setup instructions
- Follow branching conventions in repo-working-agreement.md
- Run  code review before submitting PRs

---

## Notes for Agent

- **Be concise**: Aim for 3-5 bullets per section
- **Avoid duplication**: Don't repeat what's in repo-working-agreement.md or repo-guardrails.md
- **Focus on "what" not "how"**: Save detailed procedures for other templates
- **Stay current**: Always read files fresh rather than using cached knowledge
- **Handle missing sources gracefully**: If a file doesn't exist, skip it and use others