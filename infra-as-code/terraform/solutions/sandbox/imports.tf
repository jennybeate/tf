import {
  to = module.user_assigned_identity.azurerm_user_assigned_identity.this
  id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.identity_name}"
}

import {
  to = module.aks.azapi_resource.this
  id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${local.aks_name}"
}
