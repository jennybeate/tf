variables {
  cost_center         = "cc-0000"
  environment         = "dev"
  location            = "norwayeast"
  owner               = "platform-team"
  resource_group_name = "rg-dev-example"
  solution            = "example"
  enable_telemetry    = false
}

run "identity_name_is_correct" {
  command = plan

  assert {
    condition     = module.user_assigned_identity.resource_name == "id-dev-example"
    error_message = "User assigned identity name must follow the pattern id-{environment}-{solution}."
  }
}
