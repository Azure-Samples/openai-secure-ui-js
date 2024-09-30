metadata description = 'Creates an Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}

param kind string = ''
param zoneredundant bool = true
param reserved bool = true
param sku object



module serverfarm 'br/public:avm/res/web/serverfarm:0.2.3' = {
  name: 'serverfarmDeployment'
  params: {
    // Required parameters
    name: name
    kind: kind
    location: location
    perSiteScaling: true
    skuCapacity: sku.capacity
    skuName: sku.name
    tags: tags
    zoneRedundant: zoneredundant
    reserved: reserved
  }
}

output id string = serverfarm.outputs.resourceId
output name string = serverfarm.name
