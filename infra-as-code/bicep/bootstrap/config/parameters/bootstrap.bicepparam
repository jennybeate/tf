using '../../main.bicep'

param location = 'norwayeast'
param environment = 'sbx'
param solution = 'platform'
param storageAccountName = 'stsbxplatformtfstate'
param deploymentIdentityObjectId = '' //insert here if you don't plan to use the az cli inline parameter for deployment identity object id
param userObjectId = '' //insert here if you don't plan to use the az cli inline parameter for user object id
