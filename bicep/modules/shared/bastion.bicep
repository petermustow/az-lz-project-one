// =========================================
// Azure Bastion Module
// =========================================

@description('Azure region for deployment')
param location string

@description('Naming prefix for resources')
param namingPrefix string

@description('Bastion subnet ID')
param bastionSubnetId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object

// =========================================
// Variables
// =========================================

var bastionName = '${namingPrefix}-bastion'
var bastionPublicIpName = '${namingPrefix}-bastion-pip'

// =========================================
// Public IP for Bastion
// =========================================

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: bastionPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// =========================================
// Azure Bastion
// =========================================

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableFileCopy: true
    enableIpConnect: true
    enableShareableLink: false
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// =========================================
// Diagnostic Settings
// =========================================

resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: bastion
  name: 'bastion-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// =========================================
// Outputs
// =========================================

output bastionId string = bastion.id
output bastionName string = bastion.name
output bastionPublicIp string = bastionPublicIp.properties.ipAddress
