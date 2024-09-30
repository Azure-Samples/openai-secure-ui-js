targetScope = 'subscription'

@description('Name of the environment used to generate a short unique hash for all resources.')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary location for all resources.')
@minLength(1)
param location string

@description('Name of the resource group, defaults to a generated name if not provided.')
param resourceGroupName string = ''

@description('Name of the web application.')
param webappName string = 'webapp'

@description('Name of the API service.')
param apiServiceName string = 'api'

@description('Name of the App Service Plan.')
param appServicePlanName string = ''

@description('Name of the storage account.')
param storageAccountName string = ''

@description('Location for the OpenAI resource group.')
@allowed([
  'australiaeast', 'canadaeast', 'eastus', 'eastus2', 'francecentral',
  'japaneast', 'northcentralus', 'swedencentral', 'switzerlandnorth',
  'uksouth', 'westeurope'
])
param openAiLocation string

@description('SKU of the OpenAI service.')
param openAiSkuName string = 'S0'

@description('API version for the OpenAI service.')
param openAiApiVersion string

@description('API key for the OpenAI service.')
@secure()
param openAiApiKey string = ''

@description('Location for the Static Web App.')
@allowed([
  'westus2', 'centralus', 'eastus2', 'westeurope', 'eastasia', 'eastasiastage'
])
param webappLocation string

@description('Location for the Azure Functions.')
@allowed([
  'eastus', 'northeurope', 'southeastasia', 'eastasia', 'eastus2', 
  'southcentralus', 'australiaeast', 'westus2', 'uksouth', 'eastus2euap', 
  'westus3', 'swedencentral'
])
param apiLocation string

@description('Name of the chat model.')
param chatModelName string

@description('Name of the chat deployment, defaults to the chat model name.')
param chatDeploymentName string = chatModelName

@description('Version of the chat model.')
param chatModelVersion string

@description('Capacity for the chat deployment.')
param chatDeploymentCapacity int = 15

@description('Principal ID for role assignment.')
param principalId string = ''

@description('Flag to indicate if the deployment is continuous.')
param isContinuousDeployment bool

// Load abbreviations for resource naming
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {'Environment': environmentName}
var openAiUrl = 'https://${openAi.outputs.name}.openai.azure.com'
var apiResourceName = '${abbrs.webSitesFunctions}api-${resourceToken}'
var useAzureOpenAi = empty(openAiApiKey)

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module webapp './core/host/staticwebapp.bicep' = {
  name: 'webapp'
  scope: resourceGroup
  params: {
    name: !empty(webappName) ? webappName : '${abbrs.webStaticSites}web-${resourceToken}'
    location: webappLocation
    tags: union(tags, { 'ServiceName': webappName })
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
  }
}

module api './app/api.bicep' = {
  name: 'api'
  scope: resourceGroup
  params: {
    name: apiResourceName
    location: apiLocation
    tags: union(tags, { 'ServiceName': apiServiceName })
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

// Additional modules and resources would continue similarly...

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_OPENAI_ENDPOINT string = useAzureOpenAi ? openAiUrl : ''
output AZURE_OPENAI_API_INSTANCE string = useAzureOpenAi ? openAi.outputs.name : ''
output AZURE_OPENAI_API_DEPLOYMENT_NAME string = useAzureOpenAi ? chatDeploymentName : ''
output OPENAI_API_VERSION string = useAzureOpenAi ? openAiApiVersion : ''
output OPENAI_MODEL_NAME string = chatModelName
output WEBAPP_URL string = webapp.outputs.uri
