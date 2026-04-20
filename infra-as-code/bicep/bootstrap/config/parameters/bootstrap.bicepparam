using '../../main.bicep'

param location = 'norwayeast'
param environment = 'sbx'
param solution = 'platform'
param storageAccountName = 'stsbxplatformtfstate'
param deploymentIdentityObjectId = readEnvironmentVariable('DEPLOYMENT_IDENTITY_OBJECT_ID','') //insert here if you don't plan to use the az cli inline parameter for deployment identity object id
param userObjectId = readEnvironmentVariable('USER_OBJECT_ID','') //insert here if you don't plan to use the az cli inline parameter for user object id
