param location string = resourceGroup().location
param namePrefix string = 'zrp-rickmorty'

module backend './backend.bicep' = {
  name: 'backend'
  params: {
    location: location
    namePrefix: namePrefix
  }
}

// se quiser, module frontend aqui depois

output apiName string = backend.outputs.apiName
output redisHost string = backend.outputs.redisHost
