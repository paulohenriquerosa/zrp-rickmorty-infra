param location string = resourceGroup().location
param namePrefix string = 'zrp-rickmorty'

var planName = '${namePrefix}-plan'
var apiName = '${namePrefix}-api'
var redisName = toLower('${namePrefix}-redis')
var kvName = toLower('${namePrefix}-kv')

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource apiApp 'Microsoft.Web/sites@2023-01-01' = {
  name: apiName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
    }
  }
}

resource redis 'Microsoft.Cache/Redis@2023-04-01' = {
  name: redisName
  location: location
  sku: {
    name: 'Basic'
    family: 'C'
    capacity: 0
  }
  properties: {
    enableNonSslPort: false
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  sku: {
    family: 'A'
    name: 'standard'
  }
  properties: {
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: apiApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
  }
}

var redisPrimaryKey = redis.listKeys().primaryKey
var redisConnectionString = 'rediss://:${redisPrimaryKey}@${redis.properties.hostName}:${redis.properties.sslPort}'

resource redisConnSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${kv.name}/redis-connection'
  properties: {
    value: redisConnectionString
  }
}

resource apiSettings 'Microsoft.Web/sites/config@2023-01-01' = {
  name: '${apiApp.name}/appsettings'
  properties: {
    REDIS_URL: '@Microsoft.KeyVault(SecretUri=${redisConnSecret.properties.secretUriWithVersion})'
    PORT: '3000'
    NODE_ENV: 'production'
  }
}

output apiName string = apiApp.name
output redisHost string = redis.properties.hostName
output keyVaultName string = kv.name
