data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "uai" {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = locals.location
  name = locals.identity_name
}