param location string = resourceGroup().location
param namePrefix string = 'zrp-rickmorty-api'

module backend './backend.bicep' = {
  name: 'backend'
  params: {
    location: location
    namePrefix: namePrefix
  }
}

output apiName string = backend.outputs.apiName
output redisHost string = backend.outputs.redisHost
