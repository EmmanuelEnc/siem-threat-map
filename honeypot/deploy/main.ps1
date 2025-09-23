param(
    [string]$RgName = "RgHoneyPot",
    [string]$location = "EastUS"
)

# Create Resource Group
az group create -n $RgName -l $location | Out-Null

