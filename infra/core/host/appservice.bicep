@description('Creates an Azure App Service in an existing Azure App Service plan.')
param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
@description('Name of the Application Insights instance for telemetry integration.')
param applicationInsightsName string = ''
@description('Resource ID of the existing App Service Plan.')
param appServicePlanId string
@description('Name of the Key Vault for secrets management.')
param keyVaultName string = ''
@description('Indicates if managed identity is enabled for the App Service.')
param managedIdentity bool = !empty(keyVaultName)

// Runtime Properties
@allowed([
  'dotnet', 'dotnetcore', 'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
@description('The runtime stack of the App Service.')
param runtimeName string
@description('Concatenation of runtime name and version.')
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
@description('Version of the runtime.')
param runtimeVersion string

// Microsoft.Web/sites Properties
@description('Specifies the kind of App Service, such as API app or standard web app.')
param kind string = 'app,linux'

// Microsoft.Web/sites/config
@description('List of origins that should be allowed to make cross-origin calls.')
param allowedOrigins array = []
@description('Indicates whether the app should be kept always on.')
param alwaysOn bool = true
@description('Command line to run custom startup commands.')
param appCommandLine string = ''
@secure()
@description('Application settings as key-value pairs.')
param appSettings object = {}
@description('Specifies whether client IP affinity is enabled which directs client requests from the same IP address to the same server.')
param clientAffinityEnabled bool = false
@description('Enables or disables Oryx build on deploy.')
param enableOryxBuild bool = contains(kind, 'linux')
@description('Maximum scale-out limit of the Function App if it is a function app.')
param functionAppScaleLimit int = -1
@description('Runtime version used specifically for Linux-based hosting.')
param linuxFxVersion string = runtimeNameAndVersion
@description('Minimum number of instances for auto-scaling.')
param minimumElasticInstanceCount int = -1
@description('Number of workers to be allocated.')
param numberOfWorkers int = -1
@description('Enables or disables SCM during deployment.')
param scmDoBuildDuringDeployment bool = false
@description('Specifies whether to use a 32-bit worker process.')
param use32BitWorkerProcess bool = false
@description('FTP state for the app. Allows only FTPS or disables it.')
param ftpsState string = 'FtpsOnly'
@description('Path for the health check.')
param healthCheckPath string = ''
@description('Subnet ID for integrating the app with a virtual network.')
param virtualNetworkSubnetId string = ''

module site 'br/public:avm/res/web/site:0.9.0' = {
  name: 'siteDeployment'
  params: {
    kind: kind
    name: name
    tags: tags
    serverFarmResourceId: appServicePlanId
    location: location
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
    appSettingsKeyValuePairs: union({
      ENABLE_ORYX_BUILD: string(enableOryxBuild)
      SCM_DO_BUILD_DURING_DEPLOYMENT: string(scmDoBuildDuringDeployment)
    },
    runtimeName == 'python' && appCommandLine == '' ? { PYTHON_ENABLE_GUNICORN_MULTIWORKERS: 'true'} : {},
    !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {},
    !empty(keyVaultName) ? { AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri } : {})
    managedIdentities: {
      systemAssigned: managedIdentity
    }
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      use32BitWorkerProcess: use32BitWorkerProcess
      functionAppScaleLimit: functionAppScaleLimit != -1 ? functionAppScaleLimit : null
      healthCheckPath: healthCheckPath
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : null
  }
}


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultName)) {
  name: keyVaultName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

output id string = site.outputs.resourceId
output identityPrincipalId string = site.outputs.systemAssignedMIPrincipalId
output name string = site.outputs.name
output uri string = 'https://${site.outputs.defaultHostname}'

