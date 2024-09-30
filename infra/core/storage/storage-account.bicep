metadata description = 'Creates an Azure storage account.'
param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Cool'
  'Hot'
  'Premium' ])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = true
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = true
param containers array = []
param corsRules array = []
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed([ 'AzureDnsZone', 'Standard' ])
param dnsEndpointType string = 'Standard'
param files array = []
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param queues array = []
param shareDeleteRetentionPolicy object = {}
param supportsHttpsTrafficOnly bool = true
param tables array = []
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param sku object = { name: 'Standard_LRS' }




module storageAccount 'br/public:avm/res/storage/storage-account:0.13.0' = {
  name: 'storageAccountDeployment'
  params: {
    // Required parameters
    name: name
    // Non-required parameters
    location: location
    kind: kind
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    blobServices: {
      corsRules: corsRules
      containers: [for container in containers: {
        name: container.name
      }
      
    ]
      deleteRetentionPolicyDays: 9
      deleteRetentionPolicyEnabled: true
    }
    fileServices: empty(files) ? null : {
      corsRules: corsRules
      shares: [
        {
          accessTier: 'Hot'
          name: 'default'
          shareQuota: 5120
          deletedShareRetentionDays: shareDeleteRetentionPolicy
        }
        
      ]
    }
   
    queueServices: {
      corsRules: corsRules
      queues: [for queue in queues: {
        name: queue.name
        metadata: queue.metadata ?? {}  // If metadata is missing or null, use an empty object
      }]
    }
    
    requireInfrastructureEncryption: true
    skuName: sku.name
    tableServices: {
      corsRules: corsRules
      tables: [
        for table in tables: {
          name: table.name ?? 'defaultTableName'
        }
      ]
    }
    
    
    tags: tags
  }
}

output id string = storageAccount.outputs.resourceId
output name string = storageAccount.name
output primaryEndpoints object = storageAccount.outputs.serviceEndpoints
