
#  Code Review Rules (General)

These rules apply to all code reviews in this repository and should be read together with the language-specific standards files stored alongside this document (for example, the Terraform standards file).

## Severity
- **[BLOCKER]**: Security issues, secret exposure, destructive behavior, or errors that will break CI/CD or production usage.
- **[MAJOR]**: Likely bugs, weak error handling, missing essential validation, unclear behavior, or maintainability issues that will cause incidents.
- **[MINOR]**: Style/consistency, small robustness improvements, clearer naming/messages.
- **[NIT]**: Tiny polish (formatting, wording). Prefer batching nits.

## Review principles
1. **Be specific**: Point to exact file/line/section and propose a concrete fix.
2. **Prefer safe defaults**: Fail fast, validate inputs, avoid destructive defaults.
3. **No secrets in code or logs**: Never print secrets or store them in repo.
4. **Idempotent automation**: Scripts and deployment steps should be safe to re-run.
5. **Clear observability**: Logs should explain what is happening and include relevant IDs/paths without leaking secrets.
6. **Consistency**: Follow the templates and naming conventions. Avoid custom styles per author.
7. **Use variables and locals**: Environment-specific values (Azure IDs, locations, environment names, resource names) MUST be declared as Terraform `variable` blocks or derived in `locals`. Hardcoding any value that should be parameterised is a **[BLOCKER]**.

## Reference integrity checks

Reviewers MUST check that:
- All referenced files exist and are correctly named
- Environment files, config files, and scripts referenced in pipelines actually exist
- Naming is consistent across references (case, pluralization, prefixes)
- Similar-looking names are double-checked (`live` vs `liv`, `.env` vs `.envs`)

## CI pipeline context

You review PRs immediately, before CI completes. Do not flag issues that CI will catch.

**What CI checks (do NOT duplicate):**
- Formatting via `terraform fmt -check`
- Linting via `tflint`
- Security scanning via `tfsec`
- Configuration validity via `terraform validate`
- Plan output posted to the PR comment

**What CI does NOT check (you MUST review):**
- Logic correctness — whether the plan achieves the intended outcome
- Naming convention compliance
- Tagging completeness (`environment`, `solution`, `owner`, `cost_center`)
- AVM module version acceptability
- Security issues not caught by tfsec (overly broad RBAC, missing locks, sensitive outputs)
- Reference integrity across modules and variables

## Expected reviewer behavior
- Use the output structure from templates/code-review.output.md exactly.
- Use severity tags consistently.
- If something is uncertain, state the assumption and ask for evidence (e.g., pipeline context), but still provide best-effort feedback.
- Prefer small targeted suggestions over large rewrites.

## What counts as a "pass"
A change is considered acceptable when:
- There are no [BLOCKER] findings.
- [MAJOR] findings have either been fixed or explicitly accepted with rationale.
- The code follows the relevant language template checks.