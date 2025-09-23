// bicep/law.bicep
// Simple Log Analytics Workspace for Sentinel + DCRs

param workspaceName string
param location string = resourceGroup().location
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

    // No daily cap by default (0 = unlimited). Easy for labs; watch costs in production.
    //workspaceCapping: {
     // dailyQuotaGb: 0
    //}
  }
}

// Helpful outputs for chaining into Sentinel, DCRs, and Workbooks
output workspaceId string = law.id
output customerId string = law.properties.customerId
output workspaceLocation string = law.location
output name string = law.name
