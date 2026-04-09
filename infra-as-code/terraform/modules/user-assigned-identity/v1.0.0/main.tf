module "user_assigned_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.0"

  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
  enable_telemetry    = var.enable_telemetry
}
