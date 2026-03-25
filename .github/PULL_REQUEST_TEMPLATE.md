## Summary

<!-- What does this PR do? Why? -->

## Type of change

- [ ] New module
- [ ] Module update
- [ ] Standards / templates update
- [ ] Pipeline change
- [ ] Other

## Checklist

- [ ] `terraform fmt -recursive` — no diff
- [ ] `terraform validate` — passes
- [ ] `tflint` — no errors
- [ ] `tfsec` — findings reviewed
- [ ] All variables have `type` and `description`
- [ ] All outputs have `description`
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] No hardcoded secrets or credentials
- [ ] AVM module version pinned (if applicable)
- [ ] `.terraform.lock.hcl` committed
- [ ] Terraform plan reviewed (posted automatically by CI)
