param spAppId string = ''
@secure()
param spAppSecret string = ''
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-04-01-preview' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: spAppId
        permissions: {
          secrets: [ 'get', 'list', 'set' ]
        }
      }
    ]
  }
}

resource kvSpAppId 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'client-id'
  parent: keyVault
  properties: {
    value: spAppId
  }
}

resource kvSpAppSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'client-secret'
  parent: keyVault
  properties: {
    value: spAppSecret
  }
}

// var Reader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
// var Contributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(subscription().id, 'roleAssignment', spAppId)
//   properties: {
//     roleDefinitionId: Contributor
//     principalId: spObjId
//   }
// }

