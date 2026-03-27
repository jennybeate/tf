resource "azurerm_resource_group" "sandbox" {
  location = var.location
  name     = "rg-${var.environment}-${var.solution}-sandbox"

  tags = {
    cost_center = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}

module "storage_account" {
  source = "../modules/storage-account"

  cost_center         = var.cost_center
  environment         = var.environment
  location            = var.location
  owner               = var.owner
  resource_group_name = azurerm_resource_group.sandbox.name
  solution            = var.solution
}
