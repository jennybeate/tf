
# Code Review Output Template

Use this exact structure for every review. Keep feedback concrete and actionable.
Use severity tags: [BLOCKER], [MAJOR], [MINOR], [NIT].

## Review Result

Start every review with a verdict and finding counts:

**Verdict**: ✅ Pass / ⚠️ Pass with remarks / ❌ Fail (has BLOCKERs)

| Severity | Count |
|----------|-------|
| BLOCKER  | X     |
| MAJOR    | X     |
| MINOR    | X     |
| NIT      | X     |

Rules:
- **❌ Fail**: 1 or more BLOCKERs → must be fixed before merge
- **⚠️ Pass with remarks**: 0 BLOCKERs but has MAJOR findings → should be fixed or explicitly accepted
- **✅ Pass**: No BLOCKERs or MAJORs → good to merge

---

## Findings

Group all findings by severity. Each finding MUST include **Where**, **Why**, and **Fix**.

### Blocking issues
> Must be fixed before merge

- [BLOCKER] <Short title>
  - **Where:** <file>:<line> (or function/section)
  - **Why:** <impact / standard violated>
  - **Fix:** <specific change suggestion>

### Recommended changes
> Should be fixed to improve quality, reliability, or maintainability

- [MAJOR] <Short title>
  - **Where:** …
  - **Why:** …
  - **Fix:** …

### Minor issues / style
> Non-blocking improvements. Batch nits together when possible.

- [MINOR] …
- [NIT] …

---

## Notes

Only include sections that are relevant. Skip sections with no findings.

- **Security**: Flag secret leakage, over-privileged access, or unsafe defaults
- **Idempotency**: Flag operations that are not safe to re-run
- **References**: Flag incorrect or missing file references (these are [BLOCKER])
- **Logging**: Flag missing or misleading verbose messages

These are NOT separate output sections — they should be categorized as findings above with the correct severity.

---

## Want me to help?

Always end the review by offering to help. Adapt based on the verdict:

**If ❌ Fail:**
> Want me to fix the BLOCKERs? I can apply the suggested changes for you.

**If ⚠️ Pass with remarks:**
> Want me to help fix the MAJOR findings, or do you want to address them yourself?

**If ✅ Pass:**
> Looks good! Want me to run a security check or naming validation as well?

---

## References
- **Templates used:** `code-review.rules.md`, `code-review.output.md`
- **Repo standards referenced (optional):** <paths/sections if applicable>