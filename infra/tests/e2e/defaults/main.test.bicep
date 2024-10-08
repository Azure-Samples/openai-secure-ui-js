metadata name = 'Using only defaults.'
metadata description = 'This instance deploys the module with the minimum set of required parameters.'

targetScope = 'subscription'


param resourceLocation string = deployment().location



// ============== //
// Test Execution //
// ============== //

module testDeployment '../../../main.bicep' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-test-${serviceShort}'
  params: {
    location: resourceLocation
    webappName: 'webapp'
    environmentName: '\${AZURE_ENV_NAME}'
    resourceGroupName: '\${AZURE_RESOURCE_GROUP}'
    openAiLocation: '\${AZURE_OPENAI_LOCATION=eastus2}'
    openAiApiVersion: '2024-02-01'
    chatModelName: 'gpt-35-turbo'
    chatModelVersion: '0613'
    webappLocation: 'eastus2'
    apiLocation: 'eastus2'
    isContinuousDeployment: false
    principalId: '\${AZURE_PRINCIPAL_ID}'
    openAiApiKey: '\${AZURE_OPENAI_API_KEY}'
  }
}

output testDeploymentOutputs object = testDeployment.outputs
