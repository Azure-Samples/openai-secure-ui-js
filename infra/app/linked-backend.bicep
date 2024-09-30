param staticWebAppName string
param backendResourceId string
param backendLocation string

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' existing = {
  name: staticWebAppName
}

module staticSite 'br/public:avm/res/web/static-site:0.6.0'  = {
  name: 'linkedBackend'
  params: {
    name: staticWebApp.name
    linkedBackend:{
    backendResourceId: backendResourceId
    region: backendLocation
    }
  }
}
