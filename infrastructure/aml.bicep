param name string
param env string = 'dev'
param location string = resourceGroup().location
var tenantId = subscription().tenantId
var storageAccountName = 'st${name}${env}'
var keyVaultName = 'kv${name}${env}'
var applicationInsightsName = 'appi${name}${env}'
var containerRegistryName = 'cr${name}${env}'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableSoftDelete: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  sku: {
    name: 'Standard'
  }
  name: containerRegistryName
  location: location
  properties: {
    adminUserEnabled: true
  }
}

var workspaceName = 'amlw${name}${env}'
var storageAccountId = storageAccount.id
var keyVaultId = keyVault.id
var applicationInsightsId = applicationInsights.id
var containerRegistryId = containerRegistry.id
param hbi_workspace bool = false

resource workspace 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName
  location: location
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    hbiWorkspace: hbi_workspace
  }
}

output applicationInsightsId string = applicationInsights.name
output storageAccountId string = storageAccount.name
output containerRegistryId string = containerRegistry.name
output keyVaultId string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output azureMlWorkspaceId string = workspace.id
output mlflow_uri string = workspace.properties.mlFlowTrackingUri
