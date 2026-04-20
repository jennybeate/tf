targetScope = 'subscription'

@description('Optional. Location for all resources. Defaults to norwayeast')
param location string = 'norwayeast'

@description('Optional. Storage Account Sku Name. Defaults to Standard LRS in this module, while AVM defaults would default to Standard_GRS')
param skuName string = 'Standard_LRS' 

@allowed(['sbx', 'liv', 'can', 'dev', 'prod', 'tst', 'stg', 'uat'])
@description('Optional. Environment. Defaults to sbx')
param environment string = 'sbx'

@description('Optional. Solution name. Defaults to platform')
param solution string = 'platform'

@maxLength(24)
@description('Required. Name of the Storage Account. Must be lower-case. Defaults to stsbxplatformtfstate')
param storageAccountName string = 'st${environment}${solution}tfstate'

@description('Object ID of the deployment identity used by the pipeline. Optional. Used for role assignment.')
param deploymentIdentityObjectId string?

@description('Object ID of the user testing locally. Required for role assignment making it possible to run terraform plan.')
param userObjectId string

var roleAssignments = concat(
  !empty(deploymentIdentityObjectId) ? [
    {
      principalId: deploymentIdentityObjectId
      principalType: 'ServicePrincipal'
      roleDefinitionIdOrName: 'Storage Blob Data Contributor'
    }
  ] : [],
  [
    {
      principalId: userObjectId
      principalType: 'User'
      roleDefinitionIdOrName: 'Storage Blob Data Contributor'
    }
  ]
)

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environment}-${solution}-terraform-state'
  location: location
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'tfstate-storage'
  scope: rg
  params: {
    name: storageAccountName
    location: location
    skuName: skuName
    blobServices: {
      containers: [{ name: 'tfstate', publicAccess: 'None' }]
    }
    roleAssignments: roleAssignments
      isLocalUserEnabled: false
      publicNetworkAccess: 'Enabled'
      networkAcls: {
        defaultAction: 'Allow'
        bypass: 'AzureServices'
      }
  }
}
