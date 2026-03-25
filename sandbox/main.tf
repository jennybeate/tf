resource "azurerm_resource_group" "sandbox" {
  location = var.location
  name     = "rg-${var.environment}-${var.solution}-sandbox"

  tags = {
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }
}

module "storage_account" {
  source = "../modules/storage-account"

  environment         = var.environment
  location            = var.location
  owner               = var.owner
  resource_group_name = azurerm_resource_group.sandbox.name
  solution            = var.solution
}
