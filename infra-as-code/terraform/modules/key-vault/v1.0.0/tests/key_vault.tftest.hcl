variables {
  cost_center                = "cc-0000"
  environment                = "sbx"
  location                   = "norwayeast"
  owner                      = "platform-team"
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  solution                   = "test-keyvault"
}

run "key_vault_is_rbac_enabled" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled == true
    error_message = "Key Vault must use Azure RBAC authorization, not legacy access policies."
  }

  assert {
    condition     = azurerm_key_vault.main.purge_protection_enabled == true
    error_message = "Key Vault must have purge protection enabled to prevent accidental permanent deletion."
  }

  assert {
    condition     = azurerm_key_vault.main.soft_delete_retention_days >= 7
    error_message = "Soft delete retention must be at least 7 days."
  }
}
