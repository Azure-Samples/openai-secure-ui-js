targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
// Flex Consumption functions are only supported in these regions.
// Run `az functionapp list-flexconsumption-locations --output table` to get the latest list
@allowed(['northeurope', 'southeastasia', 'eastasia', 'eastus2', 'southcentralus', 'australiaeast', 'eastus', 'northcentralus(stage)', 'westus2', 'uksouth', 'eastus2euap', 'westus3', 'swedencentral'])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

param resourceGroupName string = ''
param webappName string = 'webapp'
param apiServiceName string = 'api'
param appServicePlanName string = ''
param storageAccountName string = ''

@description('Location for the OpenAI resource group')
@allowed(['australiaeast', 'canadaeast', 'eastus', 'eastus2', 'francecentral', 'japaneast', 'northcentralus', 'swedencentral', 'switzerlandnorth', 'uksouth', 'westeurope'])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiLocation string // Set in main.parameters.json
param openAiSkuName string = 'S0'
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
param isContinuousDeployment bool // Set in main.parameters.json

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var openAiUrl = 'https://${openAi.outputs.name}.openai.azure.com'
var apiResourceName = '${abbrs.webSitesFunctions}api-${resourceToken}'
var useAzureOpenAi = empty(openAiApiKey)

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application webapp
module webapp './core/host/staticwebapp.bicep' = {
  name: 'webapp'
  scope: resourceGroup
  params: {
    name: !empty(webappName) ? webappName : '${abbrs.webStaticSites}web-${resourceToken}'
    location: webappLocation
    tags: union(tags, { 'azd-service-name': webappName })
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
  }
}

// The application backend API
module api './app/api.bicep' = {
  name: 'api'
  scope: resourceGroup
  params: {
    name: apiResourceName
    location: location
    tags: union(tags, { 'azd-service-name': apiServiceName })
    appServicePlanId: appServicePlan.outputs.id
    allowedOrigins: [webapp.outputs.uri]
    storageAccountName: storage.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    virtualNetworkSubnetId: vnet.outputs.appSubnetID
    staticWebAppName: webapp.outputs.name
    appSettings: {
      APPINSIGHTS_INSTRUMENTATIONKEY: monitoring.outputs.applicationInsightsInstrumentationKey
      AZURE_OPENAI_API_INSTANCE_NAME: useAzureOpenAi ? openAi.outputs.name : ''
      AZURE_OPENAI_API_ENDPOINT: useAzureOpenAi ? openAiUrl : ''
      AZURE_OPENAI_API_VERSION: useAzureOpenAi ? openAiApiVersion : ''
      AZURE_OPENAI_API_DEPLOYMENT_NAME: useAzureOpenAi ? chatDeploymentName : ''
      OPENAI_API_KEY: useAzureOpenAi ? '' : openAiApiKey
      OPENAI_MODEL_NAME: useAzureOpenAi ? '' : chatModelName
     }
  }
  dependsOn: useAzureOpenAi ? [openAi] : []
}

// Compute plan for the Azure Functions API
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
    reserved: true
  }
}

// Storage for Azure Functions API and Blob storage
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    containers: [
      // Deployment storage container
      {
        name: apiResourceName
      }
    ]
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: vnet.outputs.appSubnetID
          action: 'Allow'
        }
      ]
    }
  }
}

// Virtual network for Azure Functions API
module vnet './app/vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup
  params: {
    name: '${abbrs.networkVirtualNetworks}${resourceToken}'
    location: location
    tags: tags
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}

module openAi 'core/ai/cognitiveservices.bicep' = if (useAzureOpenAi) {
  name: 'openai'
  scope: resourceGroup
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiLocation
    tags: tags
    sku: {
      name: openAiSkuName
    }
    disableLocalAuth: true
    deployments: [
      {
        name: chatDeploymentName
        model: {
          format: 'OpenAI'
          name: chatModelName
          version: chatModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: chatDeploymentCapacity
        }
      }
    ]
  }
}

// Managed identity roles assignation
// ---------------------------------------------------------------------------

// User roles
module openAiRoleUser 'core/security/role.bicep' = if (!isContinuousDeployment) {
  scope: resourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    // Cognitive Services OpenAI User
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

module storageRoleUser 'core/security/role.bicep' = if (!isContinuousDeployment) {
  scope: resourceGroup
  name: 'storage-contrib-role-user'
  params: {
    principalId: principalId
    // Storage Blob Data Contributor
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'User'
  }
}

// System roles
module openAiRoleApi 'core/security/role.bicep' = {
  scope: resourceGroup
  name: 'openai-role-api'
  params: {
    principalId: api.outputs.identityPrincipalId
    // Cognitive Services OpenAI User
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleApi 'core/security/role.bicep' = {
  scope: resourceGroup
  name: 'storage-role-api'
  params: {
    principalId: api.outputs.identityPrincipalId
    // Storage Blob Data Contributor
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'ServicePrincipal'
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

output WEBAPP_URL string = webapp.outputs.uri

