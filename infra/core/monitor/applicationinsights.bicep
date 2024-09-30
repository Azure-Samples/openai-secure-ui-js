metadata description = 'Creates an Application Insights instance based on an existing Log Analytics workspace.'
param applicationInsightsName string
param dashboardName string = ''
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string



@description('Azure Application Insights, the workload\' log & metric sink and APM tool')
module applicationInsights 'br/public:avm/res/insights/component:0.3.1' = {
  name: applicationInsightsName
  params: {
    name: applicationInsightsName
    location: location
    kind: 'web'
    tags: tags
    workspaceResourceId: logAnalyticsWorkspaceId
  }
}


module applicationInsightsDashboard 'applicationinsights-dashboard.bicep' = if (!empty(dashboardName)) {
  name: 'application-insights-dashboard'
  params: {
    name: dashboardName
    location: location
    applicationInsightsName: applicationInsights.name
  }
}

output connectionString string = applicationInsights.outputs.connectionString
output id string = applicationInsights.outputs.resourceId
output instrumentationKey string = applicationInsights.outputs.instrumentationKey
output name string = applicationInsights.name
