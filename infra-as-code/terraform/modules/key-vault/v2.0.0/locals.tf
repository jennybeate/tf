locals {
  key_vault_name = "kv-${var.environment}-${var.solution}"

  # Purge protection prevents permanent deletion but blocks destroy in non-prod environments.
  # Disabled for can/dev/sbx so vaults can be freely created and destroyed.
  purge_protection_enabled = !contains(["can", "dev", "sbx"], var.environment)

  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
