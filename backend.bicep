param location string = resourceGroup().location
param namePrefix string = 'rickmorty'

var planName = '${namePrefix}-plan'
var apiName = '${namePrefix}-api'
var redisName = toLower('${namePrefix}-redis')

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

var redisUrl = 'rediss://${redis.properties.hostName}:${redis.properties.sslPort}'

resource apiSettings 'Microsoft.Web/sites/config@2023-01-01' = {
  name: '${apiApp.name}/appsettings'
  properties: {
    REDIS_URL: redisUrl
    PORT: '3000'
    NODE_ENV: 'production'
  }
}

output apiName string = apiApp.name
output redisHost string = redis.properties.hostName
