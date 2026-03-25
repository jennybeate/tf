# test-bad-names.ps1 — deliberately bad naming for skill testing
#
# NOTE: This file itself is misnamed — PowerShell scripts must use Verb-Noun.ps1 format.
#       Correct name: Deploy-VendingInfrastructure.ps1
#
# Planted issues (expected findings):
#   [BLOCKER] Storage account name contains dashes (st-can-vending) — Azure constraint
#   [MAJOR]   File name does not follow Verb-Noun.ps1 convention (see note above)
#   [MAJOR]   Environment abbreviation "canary" used instead of "can"
#   [MAJOR]   Variable $resource_group_name uses snake_case instead of camelCase
#   [MAJOR]   Variable $StorageAccount uses PascalCase instead of camelCase
#   [MINOR]   Inconsistent environment tokens: "can" and "canary" mixed across resources
#   [NIT]     Resource group missing type prefix — should start with "rsg-"

param (
    [Parameter(HelpMessage = 'Target subscription ID.')]
    [String]$SubscriptionId = "$($env:AZURE_SUBSCRIPTION_ID)",

    [Parameter(HelpMessage = 'Deployment environment.')]
    [String]$Environment = "$($env:ENVIRONMENT)"
)

$ErrorActionPreference = 'Stop'

# [MAJOR] snake_case — should be camelCase: $resourceGroupName
$resource_group_name = "infra-can-vending" # [NIT] missing type prefix "rsg-"

# [BLOCKER] dashes not allowed in storage account names
$StorageAccount = "st-can-vending" # [MAJOR] also PascalCase instead of camelCase

# [MAJOR] wrong environment abbreviation — should be "can" not "canary"
$keyVaultName = "kv-canary-vending"

# [MINOR] mixed environment tokens: "can" vs "canary"
$aksName = "aks-can-vending"
$acrName = "acr-canary-vending" # inconsistent with aksName above

Write-Verbose "Deploying to resource group: $resource_group_name" -Verbose
