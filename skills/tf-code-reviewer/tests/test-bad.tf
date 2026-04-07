# test-bad.tf — deliberately bad Terraform for skill testing
#
# Planted issues (expected findings):
#   [BLOCKER] Hardcoded secret in service_principal.client_secret
#   [BLOCKER] No backend block — local state only
#   [BLOCKER] Sensitive output not marked sensitive = true
#   [MAJOR]   Hardcoded resource names (not parameterised)
#   [MAJOR]   Missing tags on all resources
#   [MAJOR]   variable "env" has no type, description, or validation
#   [MAJOR]   variable "location" missing description
#   [MAJOR]   Unused variable "unused_param"
#   [MAJOR]   count used for multiple named resources — use for_each instead
#   [MAJOR]   azapi used where azurerm supports the resource — no explanatory comment
#   [MAJOR]   output exposes entire resource object (anti-corruption pattern violation)
#   [MAJOR]   AVM module has no version pinned — floating reference
#   [MINOR]   No validation block on variable "location"
#   [MINOR]   ignore_changes uses quoted strings — must be unquoted attribute references
#   [NIT]     General formatting — run terraform fmt
#   [NIT]     lifecycle block placed before arguments (wrong block ordering)
#   [NIT]     Resource label is plural ("storage_accounts") — should be singular
#   [NIT]     locals block is not alphabetical

terraform {
  required_version = ">= 1.0"
  # No backend block — local state only [BLOCKER]
}

provider "azurerm" {
  features {}
}

# [BLOCKER] hardcoded secret
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = "westeurope"
  resource_group_name = "my-resource-group"
  dns_prefix          = "myaks"

  service_principal {
    client_id     = "00000000-0000-0000-0000-000000000000"
    client_secret = "supersecret123"
  }
  # [MAJOR] no tags
}

# [MAJOR] hardcoded name, no tags
resource "azurerm_resource_group" "rg" {
  name     = "my-resource-group"
  location = "westeurope"
}

# [MAJOR] missing type, description, and validation
variable "env" {}

# [MINOR] no description, no validation
variable "location" {
  type    = string
  default = "westeurope"
}

# [MAJOR] unused variable
variable "unused_param" {
  type    = string
  default = "nothing"
}

# [BLOCKER] sensitive output not marked sensitive
output "aks_client_secret" {
  value = azurerm_kubernetes_cluster.aks.service_principal[0].client_secret
}

# [MAJOR] count used for multiple named resources — for_each should be used
resource "azurerm_resource_group" "env_rgs" {
  count    = 3
  name     = "rg-env-${count.index}"
  location = "westeurope"
}

# [NIT] lifecycle before arguments (wrong block ordering)
# [NIT] plural resource label "storage_accounts"
resource "azurerm_storage_account" "storage_accounts" {
  lifecycle {
    prevent_destroy = false
  }
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# [MAJOR] azapi used for a resource azurerm already supports — no explanatory comment
resource "azapi_resource" "aks_extension" {
  type      = "Microsoft.ContainerService/managedClusters/extensions@2023-01-01"
  name      = "my-extension"
  parent_id = azurerm_kubernetes_cluster.aks.id
  body = jsonencode({
    properties = {}
  })
}

# [MAJOR] output exposes entire resource object — use discrete attributes instead
output "storage_account_full" {
  description = "The full storage account resource."
  value       = azurerm_storage_account.storage_accounts
}

# [MAJOR] AVM module with no version pinned — floating reference will pull breaking changes
module "key_vault" {
  source = "Azure/avm-res-keyvault-vault/azurerm"
}

# [NIT] locals not in alphabetical order (zone before name)
locals {
  zone = "norwayeast"
  name = "example"
}

# [MINOR] ignore_changes uses quoted strings — must be unquoted attribute references
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "norwayeast"

  lifecycle {
    ignore_changes = ["tags"]
  }
}
