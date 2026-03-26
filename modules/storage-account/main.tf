resource "azurerm_storage_account" "main" {
  # required arguments
  account_replication_type = var.account_replication_type
  account_tier             = var.account_tier
  location                 = var.location
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name

  # optional arguments
  account_kind                      = var.account_kind
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = var.public_network_access_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  tags                              = local.common_tags

  # optional nested blocks
  blob_properties {
    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_retention_days > 0 ? [1] : []

      content {
        days = var.blob_soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_retention_days > 0 ? [1] : []

      content {
        days = var.container_soft_delete_retention_days
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.cmk_key_vault_key_id != null ? [1] : []

    content {
      key_vault_key_id          = var.cmk_key_vault_key_id
      user_assigned_identity_id = var.cmk_user_assigned_identity_id
    }
  }

  dynamic "identity" {
    for_each = local.identity_type != null ? [local.identity_type] : []

    content {
      type         = identity.value
      identity_ids = var.cmk_user_assigned_identity_id != null ? [var.cmk_user_assigned_identity_id] : []
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []

    content {
      bypass                     = network_rules.value.bypass
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }
}

resource "azurerm_private_endpoint" "main" {
  count = var.private_endpoint != null ? 1 : 0

  location            = var.location
  name = coalesce(var.private_endpoint.name, "pep-${var.environment}-${var.solution}")
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id
  tags                = local.common_tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-${local.storage_account_name}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = var.private_endpoint.subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_endpoint.private_dns_zone_ids) > 0 ? [1] : []

    content {
      name                 = "pdzg-${local.storage_account_name}"
      private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
    }
  }
}
