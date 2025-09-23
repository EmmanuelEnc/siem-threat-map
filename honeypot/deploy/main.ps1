param(
    [string]$projectName = "honeypot",
    [string]$resourceGroupName = "honeypot-rg",
    [string]$location = "eastus",

    [string]$workspaceName = "honeypot-law",

    [string]$vnetName = "honeypot-vnet",
    [string]$subnetName = "honeypot-subnet",
    [string]$nsgName = "honeypot-nsg",

    [string]$vmName = "honeypot-vm",
    [string]$adminUsername = "azureuser"
)

# Create Resource Group
az group create -n $resourceGroupName -l $location | Out-Null

# --- Log Analytics Workspace deployment ---
$lawOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/law.bicep `
  -p workspaceName="$workspaceName" `
    location="$location" `
  --query properties.outputs -o json | ConvertFrom-Json

$workspaceId        = $lawOutputs.workspaceId.value
$workspaceCustomerId= $lawOutputs.customerId.value

Write-Host "LAW deployed: $workspaceName @ $location (ID: $workspaceId)"

# --- Sentinel deployment ---
$sentinelOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/sentinel.bicep `
  -p workspaceId="$workspaceId" `
    location="$location" `
    workspaceName="$workspaceName" `
  --query properties.outputs -o json | ConvertFrom-Json

$sentinelSolutionId   = $sentinelOutputs.sentinelSolutionId.value
$sentinelSolutionName = $sentinelOutputs.sentinelSolutionName.value

Write-Host "Sentinel enabled: $sentinelSolutionName"

# Network (vnet, subnet, NSG with inbound allow)

# VM + AMA + disable firewall via CustomScriptExtension

# DCR + Association

# Content (Workbook, Analytics rule)

# Watchlist upload
