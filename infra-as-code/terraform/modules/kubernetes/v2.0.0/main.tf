module "user_assigned_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}


module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.5.3"

  name      = local.aks_name
  location  = var.location
  parent_id = var.resource_group_id
  
  kubernetes_version = var.kubernetes_version
  tags               = local.common_tags

  managed_identities = {
    user_assigned_resource_ids = [user_assigned_identity.identity.id]
  }

  default_agent_pool = {
    name                 = "system"
    vm_size              = var.node_vm_size
    enable_auto_scaling  = true
    min_count            = var.node_count_min
    max_count            = var.node_count_max
    os_disk_size_gb      = var.node_os_disk_size_gb
  }
}
