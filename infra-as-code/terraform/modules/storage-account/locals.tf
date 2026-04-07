locals {
  # Storage account names: no dashes, lowercase, 3-24 chars — st{environment}{solution}
  # Hyphens in solution are stripped to satisfy Azure platform constraints.
  storage_account_name = "st${var.environment}${replace(var.solution, "-", "")}"

  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
