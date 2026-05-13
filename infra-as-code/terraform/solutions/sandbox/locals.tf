locals {
  resource_group_name      = "rg-${var.environment}-${local.solution}"
  solution                 = "application-1"
  location                 = "norwayeast"
  aks_name                 = "aks-${var.environment}-${local.solution}"
  identity_name            = "id-${var.environment}-${local.solution}"
  keyvault_name            = "kv-${var.environment}-${local.solution}"
  purge_protection_enabled = !contains(["can", "dev", "sbx"], var.environment)
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = local.solution
    location    = local.location
  }
}
