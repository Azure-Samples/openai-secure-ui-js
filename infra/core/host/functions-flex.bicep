metadata description = 'Creates an Azure Function (flex consumption) in an existing Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string = ''
param appServicePlanId string
param keyVaultName string = ''
param virtualNetworkSubnetId string = ''

// Runtime Properties
@allowed([
  'dotnet', 'dotnetcore', 'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
param runtimeName string
@allowed(['3.10', '3.11', '7.4', '8.0', '10', '11', '17', '20'])
param runtimeVersion string

// Microsoft.Web/sites Properties
param kind string = 'functionapp,linux'

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
@secure()
param appSettings object = {}
param clientAffinityEnabled bool = false
param maximumInstanceCount int = 800
param instanceMemoryMB int = 2048
param minimumElasticInstanceCount int = -1
param numberOfWorkers int = -1
param healthCheckPath string = ''
param storageAccountName string

module site 'br/public:avm/res/web/site:0.9.0' = {
  name: 'siteDeployment'
  params: {
    // Required parameters
    kind: kind
    name: name
    tags: tags
    serverFarmResourceId: appServicePlanId
    
    // Non-required parameters
    appInsightResourceId: applicationInsights.id
    appSettingsKeyValuePairs: union({
      AzureFunctionsJobHost__logging__logLevel__default: 'Trace'
      FUNCTIONS_EXTENSION_VERSION: runtimeVersion
      FUNCTIONS_WORKER_RUNTIME: runtimeName
      WEBSITE_RUN_FROM_PACKAGE: '1' 
      AzureWebJobsStorage__accountName: storage.name},
      runtimeName == 'python' && appCommandLine == '' ? { PYTHON_ENABLE_GUNICORN_MULTIWORKERS: 'true'} : {},
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {},
      !empty(keyVaultName) ? { AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri } : {})
    logsConfiguration: {
      applicationLogs: {
        fileSystem: {
          level: 'Verbose'
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
    
    keyVaultAccessIdentityResourceId: keyVault.id
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      ftpsState: 'FtpsOnly'
      alwaysOn: alwaysOn
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      healthCheckPath: healthCheckPath
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : null
    storageAccountResourceId: storage.id
    storageAccountUseIdentityAuthentication: true
    clientAffinityEnabled: clientAffinityEnabled
  }
}




resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

var storageContributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource storageContainer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage // Use when specifying a scope that is different than the deployment scope
  name: guid(subscription().id, resourceGroup().id, storageContributorRole)
  properties: {
    roleDefinitionId: storageContributorRole
    principalType: 'ServicePrincipal'
    principalId: site.outputs.systemAssignedMIPrincipalId
  }
}

output id string = site.outputs.resourceId
output identityPrincipalId string = site.outputs.systemAssignedMIPrincipalId
output name string = site.name
output uri string = 'https://${site.outputs.defaultHostname}'
