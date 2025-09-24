// bicep/vm-windows.bicep
// Windows VM (Core), RDP-only inbound on NIC NSG, AMA installed, Standard HDD OS disk.
// disableFirewall param to turn off Windows Firewall via Custom Script Extension

param vmName string
param location string
param subnetId string
param nsgId string
param adminUsername string
@secure()
param adminPassword string
param vmSize string 
param publicIpSku string 
param disableFirewall bool // disable Windows Firewall via custom script extension

// --- Public IP (for RDP) ---
resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

// --- NIC ---
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

// --- VM (Windows Server Core) ---
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-core' 
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS' // Standard HDD
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

// --- Azure Monitor Agent for DCR ---
resource ama 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.10' // allow auto-upgrade of minor
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

// Custom Script Extension: disable all Windows Firewall profiles
resource disableFw 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = if (disableFirewall) {
  parent: vm
  name: 'disableWindowsFirewall'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      // Idempotent & quiet: won’t error if already disabled
      commandToExecute: 'powershell -ExecutionPolicy Bypass -NoProfile -NonInteractive -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"'
    }
  }
}

// Outputs for chaining
output vmId string = vm.id
output nicId string = nic.id
output publicIpId string = pip.id
output publicIpAddress string = pip.properties.ipAddress
