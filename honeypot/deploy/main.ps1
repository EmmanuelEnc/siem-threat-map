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
    [bool]$disableFirewall = $true,

    [string]$dcrName = "honeypot-winsec-dcr",

    [string] $watchlistAlias = "geoip",
    [string] $watchlistDisplay = "IP Geolocation (CSV)",
    [string] $itemsSearchKey = "network"
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


# --- DCR (Windows Security) + Association to VM ---
$dcrOutputs = az deployment group create `
  -g $resourceGroupName `
  -f ../bicep/dcr-windows.bicep `
  -p dcrName="$dcrName" `
     location="$location" `
     workspaceId="$workspaceId" `
  --query properties.outputs -o json | ConvertFrom-Json

$dcrId  = $dcrOutputs.dataCollectionRuleId.value

Write-Host "DCR created: $dcrId"


# --- Watchlist upload (geoip) ---
# Path to the watchlist CSV
$csvPath = "../watchlists/ip_geolocation.csv"
# Use the absolute path and pass it to az CLI with the @file syntax so the CLI reads
# the file contents instead of inlining them on the command line (avoids Windows cmd length limits)
$csvFull = (Resolve-Path $csvPath).Path

# Check if the watchlist already exists
try {
  $azExe = (Get-Command az -ErrorAction Stop).Source
} catch {
  Write-Error "Azure CLI 'az' not found in PATH. Install Azure CLI from https://aka.ms/cli and try again."
  exit 1
}

# Verify the 'az sentinel' command is available (some CLI functionality is provided by extensions).
try {
  & $azExe sentinel -h > $null 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "sentinel-not-available"
  }
} catch {
  Write-Warning "The 'az sentinel' commands are not available. Install the Sentinel extension to enable them."
  Write-Host "To search available extensions (PowerShell):"
  Write-Host "  az extension list-available -o table | Select-String -Pattern sentinel"
  Write-Host "To install a sentinel extension (example):"
  Write-Host "  az extension add --name sentinel"
  Write-Host "After installing, rerun this script."
  # don't exit here; script will likely fail when it reaches sentinel calls, but user has guidance.
}

$wlExists = & $azExe sentinel watchlist show `
  -g $resourceGroupName -w $workspaceName `
  -n $watchlistAlias `
  --query "name" -o tsv 2>$null

if ([string]::IsNullOrWhiteSpace($wlExists)) {
  Write-Host "Creating Sentinel watchlist '$watchlistAlias' from $csvPath ..."
  # Use the call operator (&) to ensure PowerShell invokes the az executable and does not
  # attempt to resolve 'sentinel' as a PowerShell command or alias.
  & $azExe sentinel watchlist create `
    -g $resourceGroupName -w $workspaceName `
    -n $watchlistAlias `
    --display-name "$watchlistDisplay" `
    --provider "custom" `
    --items-search-key "$itemsSearchKey" `
    --content-type "text/csv" `
    --source (Split-Path $csvPath -Leaf) `
    --source-type "Local file" `
    --raw-content "@$csvFull" `
  Write-Host "Watchlist created: $watchlistAlias"
} else {
  Write-Host "Updating existing watchlist '$watchlistAlias' from $csvPath ..."
  # Update using call operator to avoid PowerShell parsing issues
  & $azExe sentinel watchlist update `
    -g $resourceGroupName -w $workspaceName `
    -n $watchlistAlias `
    --display-name "$watchlistDisplay" `
    --provider "custom" `
    --items-search-key "$itemsSearchKey" `
    --content-type "text/csv" `
    --source (Split-Path $csvPath -Leaf) `
    --source-type "Local file" `
    --raw-content "@$csvFull" `
  Write-Host "Watchlist updated: $watchlistAlias"
}

# --- Workbook (AttackMap) ---
$workbookName = "AttackMap"
$wbDeployName = "workbook-attackmap"
$wbFile       = (Resolve-Path '..\bicep\workbook.bicep').Path


# Create the workbook deployment (two-call pattern not required here, but keeps it consistent)
$wbOutputs =az deployment group create `
  -g $resourceGroupName `
  -n $wbDeployName `
  -f $wbFile `
  -p workbookDisplayName="$workbookName" `
     workspaceId="$workspaceId" `
     location="$workspaceLocation" `
  --query properties.outputs -o json | ConvertFrom-Json

$workbookResourceId = $wbOutputs.workbookResourceId.value
$workbookName       = $wbOutputs.workbookName.value

Write-Host "Workbook deployed:"
Write-Host "  Name: $workbookName"
Write-Host "  Id:   $workbookResourceId"