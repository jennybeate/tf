module "this" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  location            = var.location
  name                = local.key_vault_name
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_telemetry           = false
  network_acls               = null # no firewall — suitable for sandbox without private endpoints
  purge_protection_enabled   = local.purge_protection_enabled
  role_assignments           = var.role_assignments
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = local.common_tags
}
