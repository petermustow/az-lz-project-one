// =========================================
// VPN Gateway Module
// =========================================

@description('Azure region for deployment')
param location string

@description('Naming prefix for resources')
param namingPrefix string

@description('Gateway subnet ID')
param gatewaySubnetId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object

@description('VPN Gateway SKU')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
])
param vpnGatewaySku string = 'VpnGw1'

@description('Enable BGP')
param enableBgp bool = false

// =========================================
// Variables
// =========================================

var vpnGatewayName = '${namingPrefix}-vpngw'
var vpnGatewayPublicIpName = '${namingPrefix}-vpngw-pip'

// =========================================
// Public IP for VPN Gateway
// =========================================

resource vpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: vpnGatewayPublicIpName
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
// VPN Gateway
// =========================================

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: vpnGatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    activeActive: false
    sku: {
      name: vpnGatewaySku
      tier: vpnGatewaySku
    }
    ipConfigurations: [
      {
        name: 'vpnGatewayIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: vpnGatewayPublicIp.id
          }
        }
      }
    ]
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          '172.16.0.0/24'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
        'IkeV2'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadTenant: 'https://login.microsoftonline.com/common/'
      aadAudience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
      aadIssuer: 'https://sts.windows.net/common/'
    }
  }
}

// =========================================
// Diagnostic Settings
// =========================================

resource vpnGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vpnGateway
  name: 'vpngateway-diagnostics'
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

output vpnGatewayId string = vpnGateway.id
output vpnGatewayName string = vpnGateway.name
output vpnGatewayPublicIp string = vpnGatewayPublicIp.properties.ipAddress
