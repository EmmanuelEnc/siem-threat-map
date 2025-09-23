//bicep/sentinel.bicep
// Simple Azure Sentinel instance tied to a Log Analytics Workspace

param workspaceId string
param workspaceName string
param location string

// Enabling Sentinel = deploy the SecurityInsights solution bound to the LAW
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  properties: {
    workspaceResourceId: workspaceId
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}

// Helpful outputs
output sentinelSolutionId string = sentinel.id
output sentinelSolutionName string = sentinel.name
