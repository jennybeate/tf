locals {
  common_tags = {
    cost_center = var.cost_center
    environment = var.environment
    owner       = var.owner
    solution    = var.solution
  }

  # Compute managed identity type — UserAssigned (CMK) and SystemAssigned can coexist.
  identity_type = (
    var.system_assigned_identity_enabled && var.cmk_user_assigned_identity_id != null
    ? "SystemAssigned, UserAssigned"
    : var.system_assigned_identity_enabled
    ? "SystemAssigned"
    : var.cmk_user_assigned_identity_id != null
    ? "UserAssigned"
    : null
  )

  # Storage account names may not contain hyphens; max 24 lowercase alphanumeric chars.
  storage_account_name = "st${var.environment}${var.solution}"
}
