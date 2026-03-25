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
#   [MINOR]   No validation block on variable "location"
#   [NIT]     General formatting — run terraform fmt

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

# [NIT] unused variable
variable "unused_param" {
  type    = string
  default = "nothing"
}

# [BLOCKER] sensitive output not marked sensitive
output "aks_client_secret" {
  value = azurerm_kubernetes_cluster.aks.service_principal[0].client_secret
}
