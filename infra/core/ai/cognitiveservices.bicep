metadata description = 'Creates an Azure Cognitive Services instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
@description('The custom subdomain name used to access the API. Defaults to the value of the name parameter.')
param customSubDomainName string = name
param disableLocalAuth bool = false
param deployments array = []
param kind string = 'OpenAI'

@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}

param allowedIpRules array = []
param networkAcls object = empty(allowedIpRules) ? {
  defaultAction: 'Allow'
} : {
  ipRules: allowedIpRules
  defaultAction: 'Deny'
}



module account 'br/public:avm/res/cognitive-services/account:0.7.0' = {
  name: 'accountDeployment'
  params: {
    // Required parameters
    kind: kind
    name: name
    sku: sku.name
    tags: tags
    customSubDomainName: customSubDomainName
    deployments: [for deployment in deployments: {
      model: deployment.model
      name: deployment.name
      sku: deployment.sku ?? {
        name: 'Standard'
        capacity: 20
      }
     // raiPolicyName: deployment.raiPolicyName ?? null
    }]
    location: location
    
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
    disableLocalAuth: disableLocalAuth
  }
}


output endpoint string = account.outputs.endpoint
output endpoints object = account.outputs.endpoints
output id string = account.outputs.resourceId
output name string = account.name
