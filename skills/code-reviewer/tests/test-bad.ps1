# test-bad.ps1 — deliberately bad PowerShell for skill testing
#
# Planted issues (expected findings):
#   [BLOCKER] Secret written to log via Write-Verbose
#   [BLOCKER] Hardcoded subscription ID instead of $env:AZURE_SUBSCRIPTION_ID
#   [MAJOR]   Missing comment-based help block (.SYNOPSIS, .DESCRIPTION, .EXAMPLE)
#   [MAJOR]   $ErrorActionPreference not set to 'Stop'
#   [MAJOR]   Non-idempotent — New-AzResourceGroup called without existence check
#   [MINOR]   Parameters missing HelpMessage attribute
#   [NIT]     Mixed local variable casing (camelCase and snake_case)

param (
    # [MINOR] missing HelpMessage
    [Parameter()]
    [String]$SubscriptionId = "12345678-0000-0000-0000-000000000000", # [BLOCKER] hardcoded

    [Parameter()]
    [String]$Location = "westeurope",

    [Parameter()]
    [String]$Solution = "myapp",

    [Parameter()]
    [String]$ApiSecret = "sk-supersecrettoken123" # [BLOCKER] secret in param default
)

# [MAJOR] missing $ErrorActionPreference = 'Stop'

Set-AzContext -SubscriptionId $SubscriptionId

# [BLOCKER] secret written to log
Write-Verbose "Connecting with API secret: $ApiSecret" -Verbose

$resourceGroupName = "rsg-can-platform-$Solution"
$storage_account_name = "stcan$Solution" # [NIT] snake_case mixed with camelCase

# [MAJOR] non-idempotent — no existence check before creation
New-AzResourceGroup -Name $resourceGroupName -Location $Location

# [NIT] inconsistent local variable casing continues
$deploymentName = "iac-$Solution"
$template_file = "solutions/$Solution/infra-as-code/bicep/main.bicep" # [NIT] snake_case

New-AzSubscriptionDeployment `
    -Name $deploymentName `
    -Location $Location `
    -TemplateFile $template_file
