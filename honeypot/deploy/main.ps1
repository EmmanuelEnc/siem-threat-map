param(
    [string]$projectName = "honeypot",
    [string]$resourceGroupName = "honeypot-rg",
    [string]$location = "eastus",

    [string]$workspaceName = "honeypot-law",

    [string]$vnetName = "honeypot-vnet1",
    [string]$subnetName = "honeypot-subnet1",
    [string]$nsgName = "honeypot-nsg1",

    [string]$vmName = "honeypot-vm",
    [string]$adminUsername = "azureuser",
    [string]$adminPassword = "P@ssw0rd123!",

    [string]$vmSize = "Standard_D2s_v3",
    [string]$publicIpSku = "Standard",
    [bool]$disableFirewall = $true
)

# --- Create Resource Group ---
az group create -n $resourceGroupName -l $location | Out-Null

Write-Host "Resource Group created: $resourceGroupName @ $location"


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
Write-Host "  VNet:   $vnetName"
Write-Host "  Subnet: $subnetName"
Write-Host "  NSG:    $nsgName"


# VM + AMA + disable firewall via CustomScriptExtension
$vmOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/vm-windows.bicep `
  -p vmName="$vmName" `
    location="$location" `
    subnetId="$subnetId" `
    nsgId="$nsgId" `
    adminUsername="$adminUsername" `
    adminPassword="$adminPassword" `
    vmSize="$vmSize" `
    publicIpSku="$publicIpSku" `
    disableFirewall=$disableFirewall `
  --query properties.outputs -o json | ConvertFrom-Json

$vmId = $vmOutputs.vmId.value
$nicId = $vmOutputs.nicId.value
$publicIpId = $vmOutputs.publicIpId.value
$publicIpAddress = $vmOutputs.publicIpAddress.value

Write-Host "VM deployed:"
Write-Host "  Id: $vmId"
Write-Host "  Public IP: $publicIpAddress"

# DCR + Association

# Content (Workbook, Analytics rule)

# Watchlist upload
