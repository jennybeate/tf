mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sbx-platform-terraform"
    }
  }
}

variables {
  cost_center         = "cc-0000"
  environment         = "sbx"
  location            = "norwayeast"
  owner               = "platform-team"
  resource_group_name = "rg-sbx-platform-terraform"
  solution            = "platform-terraform"
}

run "aks_cluster_name_is_correct" {
  command = plan

  assert {
    condition     = module.aks.name == "aks-sbx-platform-terraform"
    error_message = "AKS cluster name must follow the aks-{environment}-{solution} pattern."
  }
}

run "identity_uses_user_assigned" {
  command = plan

  assert {
    condition     = azurerm_user_assigned_identity.main.name == "id-sbx-platform-terraform"
    error_message = "User-assigned identity name must follow the id-{environment}-{solution} pattern."
  }
}
