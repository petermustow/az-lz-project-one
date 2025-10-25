// =========================================
// Hub Network Module
// Central hub for shared network services
// =========================================

@description('Azure region for deployment')
param location string

@description('Naming prefix for resources')
param namingPrefix string

@description('Hub VNet address prefix')
param vnetAddressPrefix string

@description('Deploy Azure Firewall')
param deployFirewall bool

@description('Deploy VPN Gateway')
param deployVpnGateway bool

@description('Deploy Azure Bastion')
param deployBastion bool

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object

// =========================================
// Variables
// =========================================

var hubVnetName = '${namingPrefix}-hub-vnet'
var firewallSubnetName = 'AzureFirewallSubnet'
var gatewaySubnetName = 'GatewaySubnet'
var bastionSubnetName = 'AzureBastionSubnet'
var managementSubnetName = 'ManagementSubnet'
var sharedServicesSubnetName = 'SharedServicesSubnet'

// Subnet address prefixes (assuming /16 for hub)
var firewallSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.1.0/24')
var gatewaySubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.2.0/27')
var bastionSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.3.0/26')
var managementSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.4.0/24')
var sharedServicesSubnetPrefix = replace(vnetAddressPrefix, '.0.0/16', '.5.0/24')

// =========================================
// Hub Virtual Network
// =========================================

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
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
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetPrefix
          serviceEndpoints: []
        }
      }
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: gatewaySubnetPrefix
          serviceEndpoints: []
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
          serviceEndpoints: []
        }
      }
      {
        name: managementSubnetName
        properties: {
          addressPrefix: managementSubnetPrefix
          networkSecurityGroup: {
            id: managementNsg.outputs.nsgId
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: sharedServicesSubnetName
        properties: {
          addressPrefix: sharedServicesSubnetPrefix
          networkSecurityGroup: {
            id: sharedServicesNsg.outputs.nsgId
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
        }
      }
    ]
  }
}

// =========================================
// Network Security Groups
// =========================================

module managementNsg '../shared/nsg.bicep' = {
  name: 'management-nsg-deployment'
  params: {
    location: location
    nsgName: '${namingPrefix}-management-nsg'
    nsgType: 'management'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

module sharedServicesNsg '../shared/nsg.bicep' = {
  name: 'shared-services-nsg-deployment'
  params: {
    location: location
    nsgName: '${namingPrefix}-shared-services-nsg'
    nsgType: 'app'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// Azure Firewall
// =========================================

module firewall '../shared/firewall.bicep' = if (deployFirewall) {
  name: 'firewall-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    firewallSubnetId: '${hubVnet.id}/subnets/${firewallSubnetName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// Azure Bastion
// =========================================

module bastion '../shared/bastion.bicep' = if (deployBastion) {
  name: 'bastion-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    bastionSubnetId: '${hubVnet.id}/subnets/${bastionSubnetName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// VPN Gateway
// =========================================

module vpnGateway '../shared/vpngateway.bicep' = if (deployVpnGateway) {
  name: 'vpn-gateway-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    gatewaySubnetId: '${hubVnet.id}/subnets/${gatewaySubnetName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// Diagnostic Settings for VNet
// =========================================

resource hubVnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: hubVnet
  name: 'hub-vnet-diagnostics'
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
// Network Watcher
// =========================================

resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' = {
  name: 'NetworkWatcher_${location}'
  location: location
  tags: tags
  properties: {}
}

// =========================================
// Outputs
// =========================================

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output hubVnetAddressSpace string = hubVnet.properties.addressSpace.addressPrefixes[0]
output firewallPrivateIp string = deployFirewall ? firewall.outputs.firewallPrivateIp : ''
output firewallId string = deployFirewall ? firewall.outputs.firewallId : ''
output bastionName string = deployBastion ? bastion.outputs.bastionName : ''
output bastionId string = deployBastion ? bastion.outputs.bastionId : ''
output vpnGatewayId string = deployVpnGateway ? vpnGateway.outputs.vpnGatewayId : ''
output managementSubnetId string = '${hubVnet.id}/subnets/${managementSubnetName}'
output sharedServicesSubnetId string = '${hubVnet.id}/subnets/${sharedServicesSubnetName}'
