mock_provider "azurerm" {}

variables {
  cost_center         = "cc-0000"
  dns_zone_name       = "k8s.example.com"
  environment         = "sbx"
  owner               = "platform-team"
  resource_group_name = "rg-sbx-dns"
  solution            = "platform-terraform"
}

run "tags_contain_environment" {
  command = plan

  assert {
    condition     = local.common_tags.environment == "sbx"
    error_message = "common_tags.environment must equal the environment variable."
  }
}

run "environment_validation_rejects_invalid_token" {
  command = plan

  expect_failures = [var.environment]

  variables {
    environment = "production"
  }
}
