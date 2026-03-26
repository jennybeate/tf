terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Backend values are supplied at init time via -backend-config flags in CI,
  # or via a local backend.hcl file when running locally.
  # See README.md for local setup instructions.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  use_oidc = true
}
