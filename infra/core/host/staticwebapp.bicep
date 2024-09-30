metadata description = 'Creates an Azure Static Web Apps instance.'
param name string
param location string = resourceGroup().location
param tags object = {}

param sku object = {
  name: 'Free'
  tier: 'Free'
}

module staticSite 'br/public:avm/res/web/static-site:0.6.0' = {
  name: 'staticSiteDeployment'
  params: {
    // Required parameters
    name: name
    // Non-required parameters
    location: location
    tags: tags
    sku: sku.name
    provider: 'Custom'
  }
}


output name string = staticSite.name
output uri string = 'https://${staticSite.outputs.defaultHostname}'
