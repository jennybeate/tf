mock_provider "azapi" {}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  cost_center         = "cc-0000"
  environment         = "sbx"
  location            = "norwayeast"
  owner               = "platform-team"
  resource_group_name = "rg-sbx-platform"
  solution            = "platform"
}

run "key_vault_name_follows_convention" {
  command = plan

  assert {
    condition     = module.this.name == "kv-sbx-platform"
    error_message = "Key Vault name must follow the pattern kv-{environment}-{solution}."
  }
}

run "purge_protection_disabled_in_sandbox" {
  command = plan

  assert {
    condition     = local.purge_protection_enabled == false
    error_message = "Purge protection must be disabled in sbx so the vault can be destroyed."
  }
}

run "purge_protection_enabled_in_production" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = local.purge_protection_enabled == true
    error_message = "Purge protection must be enabled in prod."
  }
}

run "environment_validation_rejects_invalid_token" {
  command = plan

  expect_failures = [var.environment]

  variables {
    environment = "production" # must use prod, not production
  }
}
