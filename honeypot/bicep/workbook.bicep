// bicep/workbook.bicep
// Deploy a Sentinel workbook to a given Log Analytics workspace

param workbookDisplayName string = 'AttackMap'
param workbookType string = 'sentinel'
param workspaceId string
param location string
param workbookId string = '${workspaceId}-${workbookDisplayName}'

// Load the workbook JSON template and replace the placeholder with the actual workspace ID
param serializedData string = replace(
  loadTextContent('../content/workbook.json'),
  '__WORKSPACE_ID__',
  workspaceId
)

resource wb 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: workbookId
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: serializedData
    version: '1.0'
    sourceId: workspaceId
    category: workbookType
  }
}

output workbookResourceId string = wb.id
output workbookName string = wb.name
