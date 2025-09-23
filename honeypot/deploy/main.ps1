param(
    [string]$projectName = "honeypot",
    [string]$resourceGroupName = "honeypot-rg",
    [string]$location = "eastus",

    [string]$workspaceName = "honeypot-law",

    [string]$vnetName = "honeypot-vnet1",
    [string]$subnetName = "honeypot-subnet1",
    [string]$nsgName = "honeypot-nsg1",

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
$workspaceLocation  = $lawOutputs.workspaceLocation.value

Write-Host "LAW deployed: $workspaceName @ $workspaceLocation"


# --- Sentinel deployment ---
$sentinelOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/sentinel.bicep `
  -p workspaceId="$workspaceId" `
    location="$workspaceLocation" `
    workspaceName="$workspaceName" `
  --query properties.outputs -o json | ConvertFrom-Json

$sentinelSolutionId   = $sentinelOutputs.sentinelSolutionId.value
$sentinelSolutionName = $sentinelOutputs.sentinelSolutionName.value

Write-Host "Sentinel enabled: $sentinelSolutionName"


# --- Network (VNet, Subnet, NSG attach) ---
$netOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/network.bicep `
  -p vnetName="$vnetName" `
    subnetName="$subnetName" `
    nsgName="$nsgName" `
    location="$location" `
  --query properties.outputs -o json | ConvertFrom-Json

$vnetId   = $netOutputs.vnetId.value
$subnetId = $netOutputs.subnetId.value
$nsgId    = $netOutputs.nsgId.value

Write-Host "Network ready:"
Write-Host "  VNet:   $vnetName ($vnetId)"
Write-Host "  Subnet: $subnetName ($subnetId)"
Write-Host "  NSG:    $nsgName ($nsgId)"

# VM + AMA + disable firewall via CustomScriptExtension

# DCR + Association

# Content (Workbook, Analytics rule)

# Watchlist upload
