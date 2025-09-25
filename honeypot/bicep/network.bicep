// bicep/network.bicep
// VNet + Subnet + NSG (inbound allow-all) and attach NSG to the subnet

param vnetName string
param subnetName string
param nsgName string
param location string

// address spaces defaults
param vnetAddressPrefix string = '10.10.0.0/16'
param subnetAddressPrefix string = '10.10.1.0/24'

// Network Security Group with 1 inbound allow-all rule
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-All-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Handy outputs for chaining to NIC/VM templates
output subnetId string = vnet.properties.subnets[0].id
output nsgId string = nsg.id
