resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  sku_name                   = var.sku_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  rbac_authorization_enabled  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
