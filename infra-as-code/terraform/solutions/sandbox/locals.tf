locals {
  resource_group_name = "rg-${var.environment}-${local.solution}"
  identity_name = "uai-${var.environment}-${local.solution}"
  solution = "application-1"
  location = "norwayeast"
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = local.solution
  }
}
