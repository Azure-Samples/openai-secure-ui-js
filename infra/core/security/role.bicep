metadata description = 'Creates a role assignment for a service principal.'
param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param roleDefinitionId string



module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    // Required parameters
    name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
    // Non-required parameters
    roleAssignments: [
      {
        name: 'b1a2c427-c4b1-435a-9b82-40c1b59537ac'
        principalId: principalId
        principalType: principalType
        roleDefinitionIdOrName: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
      }
    ]
  }
}
