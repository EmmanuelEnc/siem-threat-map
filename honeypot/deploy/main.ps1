param(
    [string]$RgName = "RgHoneyPot",
    [string]$Location = "EastUS",
    [string]$ProjectName = "honeypot" 
)

# Create Resource Group
az group create -n $RgName -l $Location | Out-Null

# Deploy LAW
az deployment group create `
  -g $RgName `
  -f ../bicep/law.bicep `
  -p workspaceName="$ProjectName-law" location="$Location" 
# Sentinel 

# Network (vnet, subnet, NSG with inbound allow)

# VM + AMA + disable firewall via CustomScriptExtension

# DCR + Association

# Content (Workbook, Analytics rule)

# Watchlist upload
