locals {
  aks_name            = "aks-${var.environment}-${var.solution}"
  identity_name       = "id-${var.environment}-${var.solution}"
  resource_group_name = "rg-${var.environment}-${var.solution}"

  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
