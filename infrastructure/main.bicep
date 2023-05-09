@description('Specifies the name (prefix) of resources.')
param name string

@description('Specifies the name of the environment.')
@allowed([
  'dev'
  'qa'
  'prod'
])
param env string = 'dev'

param location string = deployment().location
var rgName = 'rg-${name}-${env}'

param sqlAdminLogin string = 'pooya'
@secure()
param sqlAdminPassword string = 'myAdminP@55'
@description('Specifies current machine\'s public IP. If provided, it will be whitelisted to access SQL server.')
param userPublicIp string = ''

param spAppId string = ''
@secure()
param spAppSecret string = ''

targetScope = 'subscription'
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module aml 'aml.bicep' = {
  name: 'Azure-Ml-Workspace'
  scope: rg
  params: {
    name: name
    env: env
    location: location
  }
}

module sql 'sql.bicep' = {
  name: 'Azure-SQL-Server-DB'
  scope: rg
  params: {
    name: name
    env: env
    location: location
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    keyVaultName: aml.outputs.keyVaultId
    userPublicIp: userPublicIp
  }
  dependsOn: [
    aml
  ]
}

module fn 'functionapp.bicep' = {
  name: 'Azure-Function-App'
  scope: rg
  params: {
    name: name
    env: env
    location: location
    applicationInsightsName: aml.outputs.applicationInsightsId
    storageAccountName: aml.outputs.storageAccountId
    keyVaultName: aml.outputs.keyVaultId
  }
  dependsOn: [
    sql
  ]
}

module sp 'serviceprincipal.bicep' = {
  name: 'ServicePrincipal-access'
  scope: rg
  params: {
    keyVaultName: aml.outputs.keyVaultId
    spAppId: spAppId
    spAppSecret: spAppSecret
  }
  dependsOn: [
    fn
  ]
}



output name string = name 
output env string = env 
output location string = location
output subscriptionId string = subscription().subscriptionId
output resourceGroup string = rg.name
output amlWorkspace string = aml.outputs.azureMlWorkspaceId
output keyVault string = aml.outputs.keyVaultId 
output keyVaultUri string = aml.outputs.keyVaultUri 
output fnBaseUrl string = fn.outputs.fn_url
output mlflowTrackingUri string = aml.outputs.mlflow_uri
