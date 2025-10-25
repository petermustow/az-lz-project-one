// =========================================
// Spoke Network Module
// Isolated workload network peered to hub
// =========================================

@description('Azure region for deployment')
param location string

@description('Naming prefix for resources')
param namingPrefix string

@description('Spoke number for naming')
param spokeNumber int

@description('Spoke VNet address prefix')
param vnetAddressPrefix string

@description('Hub VNet ID for peering')
param hubVnetId string

@description('Hub VNet name for peering')
param hubVnetName string

@description('Hub resource group name')
param hubResourceGroupName string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object

// =========================================
// Variables
// =========================================

var spokeVnetName = '${namingPrefix}-spoke-${padLeft(spokeNumber, 2, '0')}-vnet'
var webTierSubnetName = 'WebTierSubnet'
var appTierSubnetName = 'AppTierSubnet'
var dataTierSubnetName = 'DataTierSubnet'

// Subnet address prefixes (assuming /16 for spoke)
var webTierSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.1.0/24')
var appTierSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.2.0/24')
var dataTierSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.3.0/24')

// =========================================
// Network Security Groups
// =========================================

module webTierNsg '../shared/nsg.bicep' = {
  name: 'spoke-${padLeft(spokeNumber, 2, '0')}-web-nsg-deployment'
  params: {
    location: location
    nsgName: '${namingPrefix}-spoke-${padLeft(spokeNumber, 2, '0')}-web-nsg'
    nsgType: 'web'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

module appTierNsg '../shared/nsg.bicep' = {
  name: 'spoke-${padLeft(spokeNumber, 2, '0')}-app-nsg-deployment'
  params: {
    location: location
    nsgName: '${namingPrefix}-spoke-${padLeft(spokeNumber, 2, '0')}-app-nsg'
    nsgType: 'app'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

module dataTierNsg '../shared/nsg.bicep' = {
  name: 'spoke-${padLeft(spokeNumber, 2, '0')}-data-nsg-deployment'
  params: {
    location: location
    nsgName: '${namingPrefix}-spoke-${padLeft(spokeNumber, 2, '0')}-data-nsg'
    nsgType: 'data'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// Spoke Virtual Network
// =========================================

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: webTierSubnetName
        properties: {
          addressPrefix: webTierSubnetPrefix
          networkSecurityGroup: {
            id: webTierNsg.outputs.nsgId
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: appTierSubnetName
        properties: {
          addressPrefix: appTierSubnetPrefix
          networkSecurityGroup: {
            id: appTierNsg.outputs.nsgId
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: dataTierSubnetName
        properties: {
          addressPrefix: dataTierSubnetPrefix
          networkSecurityGroup: {
            id: dataTierNsg.outputs.nsgId
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// =========================================
// VNet Peering - Spoke to Hub
// =========================================

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: 'peer-to-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// =========================================
// VNet Peering - Hub to Spoke (module deployment)
// =========================================

module hubToSpokePeering 'peering.bicep' = {
  name: 'hub-to-spoke-${padLeft(spokeNumber, 2, '0')}-peering-deployment'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: spokeVnet.id
    spokeVnetName: spokeVnetName
  }
}

// =========================================
// Diagnostic Settings for VNet
// =========================================

resource spokeVnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: spokeVnet
  name: 'spoke-vnet-diagnostics'
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
    metrics: [
      {
        category: 'AllMetrics'
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

output spokeVnetId string = spokeVnet.id
output spokeVnetName string = spokeVnet.name
output spokeVnetAddressSpace string = spokeVnet.properties.addressSpace.addressPrefixes[0]
output webTierSubnetId string = '${spokeVnet.id}/subnets/${webTierSubnetName}'
output appTierSubnetId string = '${spokeVnet.id}/subnets/${appTierSubnetName}'
output dataTierSubnetId string = '${spokeVnet.id}/subnets/${dataTierSubnetName}'
