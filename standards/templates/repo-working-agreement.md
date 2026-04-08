# Repo Working Agreements

## Contents

- [Code changes](#code-changes)
- [Reviews](#reviews)
  - [Pipelines](#pipelines)
- [Branching, pull requests and CI/CD](#branching-pull-requests-and-cicd)
  - [Branching model](#branching-model)
  - [Pull request requirements](#pull-request-requirements)
  - [Merge strategy](#merge-strategy)
  - [CI/CD and environment flow](#cicd-and-environment-flow)
- [Network access and VPN](#network-access-and-vpn)
  - [VPN per environment](#vpn-per-environment)
  - [PIM (Privileged Identity Management)](#pim-privileged-identity-management)
- [GitHub Actions workflows](#github-actions-workflows)
  - [Structure](#structure)
  - [Approval gates](#approval-gates)
  - [Runners](#runners)
  - [Environment configuration](#environment-configuration)
  - [Review expectations](#review-expectations)

---

These agreements define how we collaborate and make changes in this repository.
They are expected to be followed for all contributions.

## Code changes
- One logical change per pull request
- Keep diffs small and easy to review
- Avoid unrelated refactors in the same PR

## Reviews
- All changes require review
- Use `code-reviewer` as the default entry point
- Use language-specific code reviewers when applicable
- Severity levels must be applied consistently:
  - **BLOCKER**: Must be fixed before merge
  - **MAJOR**: Must be fixed or explicitly accepted
  - **MINOR / NIT**: Improvements and polish

### Pipelines
Deployments are handled through three pipelines:

- **Canary pipeline**
  - Triggers on push to `feat/*` and `fix/*`
  - Deploys to the canary environment for fast feedback

- **Template pipeline**
  - Shared pipeline with required inputs
  - Used to standardize deployments across environments

- **Production pipeline**
  - Triggers only from the `main` branch
  - Ensures code has passed review and validation before production

Pipeline failures should be automatically posted to Slack or equivalent:
- `#azure-platform-notifications`
- `#azure-platform-notifications-canary`

## Branching, pull requests and CI/CD

### Branching model
- Default branch: `main`
- All work happens in short-lived branches created from `main`
- Branch naming:
  - `feat/<short-description>`
  - `fix/<short-description>`
- The `main` branch must always be deployable

### Pull request requirements
- Minimum one approval from another platform team member
- All required CI checks must pass
- Changes must comply with GitOps principles
- Conversations must be resolved before merge

Pull requests must clearly describe:
- What changed
- Why the change is needed
- How the change was validated (for example: local build, canary deployment, sync status)

### Merge strategy
- Merge method: **Squash merge**
- The pull request title becomes the commit message
- Titles must be clear, descriptive, and action-oriented

### CI/CD and environment flow
- `feat/*` and `fix/*` branches deploy automatically to the **canary** environment
- The `main` branch deploys to the **live pre-production** environment

This ensures fast feedback in canary, reviewed and validated changes in live,
and no direct production impact from this repository.

## Network access and VPN

Connecting to Azure services (databases, AKS clusters, private endpoints, etc.) requires a VPN connection. There is no direct access from the public internet.

### VPN per environment 
- **Canary**: `vnet-can-hub02`
- **Live**: `vnet-liv-hub02`

You must be connected to the correct VPN for the environment you are working with. Pipeline runners are already connected — VPN is primarily needed for local debugging and manual validation.

### PIM (Privileged Identity Management)

Some operations require elevated permissions through Azure PIM:
- Activating roles before performing privileged actions (e.g., Owner, Contributor on production)
- PIM activation is time-limited and must be requested per session
- Scripts should verify required permissions and provide clear error messages when access is insufficient

## GitHub Actions workflows
Workflows must align with the platform pipeline design standards.

For complete YAML reference implementations and examples, see [Pipeline Design documentation](nimtech-intellectual-property/docs/pipeline-design.md).

### Structure
- **Canary workflow**
  - Triggers on `feat/*` and `fix/*`
  - Uses default input values
- **Live workflow**
  - Uses `workflow_dispatch` only
  - No default input values
  - Requires approval
- **Template workflow**
  - Follows `validate → approval → deploy` job structure

### Approval gates
- Canary workflows must use the `approval-bypass` environment
- Live workflows must use the `approval` environment

### Runners
- Canary: `canary-<customer>-ubuntu-latest`
- Live: `<customer>-ubuntu-latest`

### Environment configuration
- `Get-EnvironmentConfig.ps1` must be executed before any Azure operation

### Review expectations
- Workflow changes must be reviewed against the pipeline design.
- Any findings should include the **exact YAML change** required to fix the issue