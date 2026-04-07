
#  Code Review Rules (General)

These rules apply to all code reviews in this repository and should be read together with the language-specific standards files stored alongside this document (for example, the PowerShell and Bicep standards files).

## Severity

These severity levels apply to all reviews in this repository — code, infrastructure, documentation, and naming.

- **[BLOCKER]**: Must be fixed before merge. Security issues, secret exposure, breaking functionality, platform constraint violations, or errors that will break CI/CD or production usage.
- **[MAJOR]**: Must be fixed or explicitly accepted with rationale before merge. Likely bugs, weak error handling, missing essential validation, standard violations that harm consistency, or maintainability issues that risk incidents.
- **[MINOR]**: Should be addressed but does not block merge. Style/consistency issues, small robustness improvements, names or messages that are inconsistent but don't break functionality.
- **[NIT]**: Optional polish — formatting, wording, ordering preferences. Prefer batching nits into a single suggestion.

## Review principles
1. **Be specific**: Point to exact file/line/section and propose a concrete fix.
2. **Prefer safe defaults**: Fail fast, validate inputs, avoid destructive defaults.
3. **No secrets in code or logs**: Never print secrets or store them in repo.
4. **Idempotent automation**: Scripts and deployment steps should be safe to re-run.
5. **Clear observability**: Logs should explain what is happening and include relevant IDs/paths without leaking secrets.
6. **Consistency**: Follow the templates and naming conventions. Avoid custom styles per author.
7. **Use environment variables**: Environment-specific values (Azure IDs, locations, environment names, resource names) MUST come from the repository environment files (`.canary.env` / `.env`) via `$env:` variables in PowerShell or `readEnvironmentVariable()` in Bicep `.bicepparam` files. Hardcoding any value that exists in these files is a **[BLOCKER]**.

## Reference integrity checks

Reviewers MUST check that:
- All referenced files exist and are correctly named
- Environment files, config files, and scripts referenced in pipelines actually exist
- Naming is consistent across references (case, pluralization, prefixes)
- Similar-looking names are double-checked (`live` vs `liv`, `.env` vs `.envs`)

## CI pipeline context

You review PRs immediately, before CI completes. Do not flag issues that CI will catch.

**What CI checks (do NOT duplicate):**
- Documentation builds via MkDocs (`preview-docs.yml`)
- Docs preview deployment to gh-pages

**What CI does NOT check (you MUST review):**
- PowerShell script syntax, logic, and standards compliance
- Workflow YAML correctness and pattern compliance
- Security issues (secrets, permissions, hardcoded values)
- Naming conventions and reference integrity

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