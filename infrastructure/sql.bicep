param name string
param env string
param location string  
param sqlAdminLogin string
@secure() 
param sqlAdminPassword string
param keyVaultName string
param userPublicIp string
var sqlServerName = 'sqlsrvr${name}${env}'
var sqlDatabaseName = 'sqldb${name}${env}'


resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: sqlDatabaseName
  location: location
  parent: sqlServer
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    // edition: 'Basic'
    maxSizeBytes: 1073741824
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing= {
  name: keyVaultName
}



resource kvServername 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'sqlserver'
  parent: keyVault
  properties: {
    value: sqlServer.properties.fullyQualifiedDomainName
  }
}

resource kvDatabase 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'sqldatabase'
  parent: keyVault
  properties: {
    value: sqlDatabase.name
  }
}

resource kvSqlUsername 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'sqlusername'
  parent: keyVault
  properties: {
    value: sqlAdminLogin
  }
}

resource kvSqlPassword 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'sqlpassword'
  parent: keyVault
  properties: {
    value: sqlAdminPassword
  }
}

resource kvSqlConnStr 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'sqlconnstr'
  parent: keyVault
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabase.name};Uid=${sqlAdminLogin};Pwd=${sqlAdminPassword};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
  }
}

resource sqlFirewallRuleMe 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if(!empty(userPublicIp)) {
  name: 'creator-ip'
  parent: sqlServer
  properties: {
    endIpAddress: userPublicIp
    startIpAddress: userPublicIp
  }
}

resource sqlFirewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if(!empty(userPublicIp)) {
  name: 'allow-azure-ip'
  parent: sqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}
