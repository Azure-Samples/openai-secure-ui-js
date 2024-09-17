param name string
param location string = resourceGroup().location
param tags object = {}

param appServicePlanId string
param storageAccountName string
param virtualNetworkSubnetId string
param applicationInsightsName string
param allowedOrigins array
param appSettings object
param staticWebAppName string = ''

module apiFlex '../core/host/functions-flex.bicep' = {
  name: 'api-flex'
  scope: resourceGroup()
  params: {
    name: name
    location: location
    tags: tags
    allowedOrigins: allowedOrigins
    alwaysOn: false
    runtimeName: 'node'
    runtimeVersion: '20'
    appServicePlanId: appServicePlanId
    storageAccountName: storageAccountName
    applicationInsightsName: applicationInsightsName
    virtualNetworkSubnetId: virtualNetworkSubnetId
    appSettings: appSettings
  }
}

// Link the Function App to the Static Web App
module linkedBackend './linked-backend.bicep' = {
  name: 'linkedbackend'
  scope: resourceGroup()
  params: {
    staticWebAppName: staticWebAppName
    backendResourceId: apiFlex.outputs.id
    backendLocation: location
  }
}

output identityPrincipalId string = apiFlex.outputs.identityPrincipalId
output name string = apiFlex.outputs.name
output uri string = apiFlex.outputs.uri
