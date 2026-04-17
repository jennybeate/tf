locals {
  common_tags = {
    costCenter  = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}
