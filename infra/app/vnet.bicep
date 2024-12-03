@description('Specifies the name of the virtual network.')
param name string

@description('Specifies the location.')
param location string = resourceGroup().location

@description('Specifies the name of the subnet for Function App virtual network integration.')
param appSubnetName string = 'app'

param tags object = {}



module virtualNetwork 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: 'virtualNetworkDeployment'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    name: name
    location: location
    vnetEncryptionEnforcement: 'AllowUnencrypted'
    vnetEncryption: false
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: appSubnetName
        delegation: 'Microsoft.App/environments'
        serviceEndpoints: [
          'Microsoft.Storage'
        ]
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    tags: tags
  }
}

output appSubnetName string = virtualNetwork.outputs.subnetNames[0]
output appSubnetID string = virtualNetwork.outputs.subnetResourceIds[0]
