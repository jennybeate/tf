data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "identity" {
  resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
  location            = var.location
  name = local.identity_name
}