targetScope = 'subscription'

param location string = 'norwayeast'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rsg-sbx-platform-terraform-state'
  location: location
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'tfstate-storage'
  scope: rg
  params: {
    name: 'stsbxplatformtfstate'
    location: location
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Disabled'
    blobServices: {
      containers: [{ name: 'tfstate', publicAccess: 'None' }]
    }
  }
}
