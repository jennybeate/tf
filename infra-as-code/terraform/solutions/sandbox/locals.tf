locals {
  resource_group_name = "rg-${var.environment}-${locals.solution}"
  identity_name = "uai-${var.environment}-${locals.solution}"
  solution = "application-1"
  location = "norwayeast"
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = locals.solution
  }
}
