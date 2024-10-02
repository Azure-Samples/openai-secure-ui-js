metadata description = 'Creates a Log Analytics workspace.'
param name string
param location string = resourceGroup().location
param tags object = {}


module workspace 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: 'workspaceDeployment'
  params: {
    // Required parameters
    name: name
    // Non-required parameters
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
  }
}

output id string = workspace.outputs.resourceId
output name string = workspace.outputs.name
