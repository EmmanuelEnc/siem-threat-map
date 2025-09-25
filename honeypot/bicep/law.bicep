// bicep/law.bicep
// Simple Log Analytics Workspace for Sentinel + DCRs

param workspaceName string
param location string 
param retentionDays int = 30   // Default retention; adjust as needed

// We’ll hardcode the common SKU and recommended features.
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays

    // Keep public endpoints ON so Cloud Shell, agents, and portal work out of the box.
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'

    // Prefer RBAC over shared keys for access to logs.
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Helpful outputs for chaining into Sentinel, DCRs, and Workbooks
output workspaceId string = law.id
output workspaceLocation string = law.location
