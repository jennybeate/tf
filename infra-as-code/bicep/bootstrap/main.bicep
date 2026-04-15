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

@secure()
param deploymentIdentityObjectId string

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
    roleAssignments: [
            {
              principalId: deploymentIdentityObjectId
              principalType: 'ServicePrincipal'
              roleDefinitionIdOrName: 'BlobDataOwner'
            }
          ]
      isLocalUserEnabled: false
      publicNetworkAccess: 'Enabled'
  }
}
