targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
// Flex Consumption functions are only supported in these regions.
// Run `az functionapp list-flexconsumption-locations --output table` to get the latest list
@allowed([
  'northeurope'
  'southeastasia'
  'eastasia'
  'eastus2'
  'southcentralus'
  'australiaeast'
  'eastus'
  'westus2'
  'uksouth'
  'eastus2euap'
  'westus3'
  'swedencentral'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

param resourceGroupName string = ''
param webappName string = 'webapp'
param apiServiceName string = 'api'

@description('Location for the OpenAI resource group')
@allowed([
  'australiaeast'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'northcentralus'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
  'westeurope'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiLocation string // Set in main.parameters.json
param openAiApiVersion string // Set in main.parameters.json

@secure()
param openAiApiKey string = ''

// Location is not relevant here as it's only for the built-in api
// which is not used here. Static Web App is a global service otherwise
@description('Location for the Static Web App')
@allowed(['westus2', 'centralus', 'eastus2', 'westeurope', 'eastasia', 'eastasiastage'])
@metadata({
  azd: {
    type: 'location'
  }
})
param webappLocation string // Set in main.parameters.json


param chatModelName string // Set in main.parameters.json
param chatDeploymentName string = chatModelName
param chatModelVersion string // Set in main.parameters.json
param chatDeploymentCapacity int = 15

// Id of the user or app to assign application roles
param principalId string = ''

// Differentiates between automated and manual deployments
param isContinuousIntegration bool // Set in main.parameters.json

// ---------------------------------------------------------------------------
// Common variables

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var principalType = isContinuousIntegration ? 'ServicePrincipal' : 'User'
var openAiUrl = 'https://${openAi.outputs.name}.openai.azure.com'
var apiResourceName = '${abbrs.webSitesFunctions}api-${resourceToken}'
var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
var useAzureOpenAi = empty(openAiApiKey)

// ---------------------------------------------------------------------------
// Resources

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application webapp
module webapp 'br/public:avm/res/web/static-site:0.7.0' = {
  name: 'webapp'
  scope: resourceGroup
  params: {
    name: webappName
    location: webappLocation
    tags: union(tags, { 'azd-service-name': webappName })
    sku: 'Standard'
  }
}
// Need to declare the linked backend module separately to avoid circular dependencies
module linkedBackend './app/linked-backend.bicep' = {
  name: 'linkedBackend'
  scope: resourceGroup
  params: {
    staticWebAppName: webappName
    backendResourceId: function.outputs.resourceId
    backendLocation: location
  }
}

// The application backend API
module function 'br/public:avm/res/web/site:0.13.0' = {
  name: 'api'
  scope: resourceGroup
  params: {
    tags: union(tags, { 'azd-service-name': apiServiceName })
    location: location
    kind: 'functionapp,linux'
    name: apiResourceName
    serverFarmResourceId: appServicePlan.outputs.resourceId
    appInsightResourceId: monitoring.outputs.applicationInsightsResourceId
    managedIdentities: { systemAssigned: true }
    appSettingsKeyValuePairs: {
      AZURE_OPENAI_API_INSTANCE_NAME: useAzureOpenAi ? openAi.outputs.name : ''
      AZURE_OPENAI_API_ENDPOINT: useAzureOpenAi ? openAiUrl : ''
      AZURE_OPENAI_API_VERSION: useAzureOpenAi ? openAiApiVersion : ''
      AZURE_OPENAI_API_DEPLOYMENT_NAME: useAzureOpenAi ? chatDeploymentName : ''
      OPENAI_API_KEY: useAzureOpenAi ? '' : openAiApiKey
      OPENAI_MODEL_NAME: useAzureOpenAi ? '' : chatModelName
    }
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      cors: {
        allowedOrigins: [ 'https://portal.azure.com', 'https://ms.portal.azure.com', webapp.outputs.defaultHostname]
      }
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.outputs.primaryBlobEndpoint}${apiResourceName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 800
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'node'
        version: '20'
      }
    }
    storageAccountResourceId: storage.outputs.resourceId
    storageAccountUseIdentityAuthentication: true
    virtualNetworkSubnetId: vnet.outputs.subnetResourceIds[0]
  }
  dependsOn: useAzureOpenAi ? [openAi] : []
}

// Compute plan for the Azure Functions API
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    tags: tags
    location: location
    skuName: 'FC1'
    reserved: true
  }
}

// Storage for Azure Functions API and Blob storage
module storage 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: storageAccountName
    tags: tags
    location: location
    skuName: 'Standard_LRS'
    allowSharedKeyAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: vnet.outputs.subnetResourceIds[0]
          action: 'Allow'
        }
      ]
    }
    blobServices: {
      containers: [
        {
          name: apiResourceName
        }
      ]
    }
    roleAssignments: [
      {
        principalId: principalId
        principalType: principalType
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
    ]
  }
}

// Virtual network for Azure Functions API
module vnet 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'vnet'
  scope: resourceGroup
  params: {
    name: '${abbrs.networkVirtualNetworks}${resourceToken}'
    location: location
    tags: tags
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      {
        name: 'app'
        addressPrefix: '10.0.1.0/24'
        delegation: 'Microsoft.App/environments'
        serviceEndpoints: ['Microsoft.Storage']
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// Monitor application with Azure Monitor
module monitoring 'br/public:avm/ptn/azd/monitoring:0.1.1' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    tags: tags
    location: location
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  }
}

module openAi 'br/public:avm/res/cognitive-services/account:0.9.2' = if (useAzureOpenAi) {
  name: 'openai'
  scope: resourceGroup
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiLocation
    tags: tags
    kind: 'OpenAI'
    customSubDomainName: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    publicNetworkAccess: 'Enabled'
    sku: 'S0'
    deployments: [
      {
        name: chatDeploymentName
        model: {
          format: 'OpenAI'
          name: chatModelName
          version: chatModelVersion
        }
        sku: {
          name: 'GlobalStandard'
          capacity: chatDeploymentCapacity
        }
      }
    ]
    disableLocalAuth: true
    roleAssignments: [
      {
        principalId: principalId
        principalType: principalType
        roleDefinitionIdOrName: 'Cognitive Services OpenAI User'
      }
    ]
  }
}


// ---------------------------------------------------------------------------
// System roles assignation

module openAiRoleApi 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  scope: resourceGroup
  name: 'openai-role-api'
  params: {
    principalId: function.outputs.systemAssignedMIPrincipalId
    roleName: 'Cognitive Services User'
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    resourceId: openAi.outputs.resourceId
  }
}

module storageRoleApi 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  scope: resourceGroup
  name: 'storage-role-api'
  params: {
    principalId: function.outputs.systemAssignedMIPrincipalId
    roleName: 'Storage Blob Data Contributor'
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    resourceId: storage.outputs.resourceId
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

output AZURE_OPENAI_ENDPOINT string = useAzureOpenAi ? openAiUrl : ''
output AZURE_OPENAI_API_INSTANCE_ string = useAzureOpenAi ? openAi.outputs.name : ''
output AZURE_OPENAI_API_DEPLOYMENT_NAME string = useAzureOpenAi ? chatDeploymentName : ''
output OPENAI_API_VERSION string = useAzureOpenAi ? openAiApiVersion : ''
output OPENAI_MODEL_NAME string = chatModelName

output WEBAPP_URL string = webapp.outputs.defaultHostname
