param location string = resourceGroup().location

@description('Name of the virtual network resource.')
param virtualNetworkName string = 'HoneyPotVNet'

@description('Array of address blocks reserved for this virtual network, in CIDR notation.')
param addressSpace object = {
  addressPrefixes: [
    '10.1.0.0/16'
  ]
}

@description('Array of subnet objects for this virtual network.')
param subnets array = [
  {
    name: 'default'
    properties: {
      addressPrefixes: [
        '10.1.0.0/24'
      ]
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: addressSpace
    subnets: subnets
  }
}

output virtualNetworkId string = vnet.id
