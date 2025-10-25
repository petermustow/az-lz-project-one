// =========================================
// VNet Peering Module (Hub to Spoke)
// =========================================

@description('Hub VNet name')
param hubVnetName string

@description('Spoke VNet ID')
param spokeVnetId string

@description('Spoke VNet name')
param spokeVnetName string

// =========================================
// Hub VNet Resource
// =========================================

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

// =========================================
// VNet Peering - Hub to Spoke
// =========================================

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hubVnet
  name: 'peer-to-${spokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
  }
}

// =========================================
// Outputs
// =========================================

output peeringName string = hubToSpokePeering.name
output peeringId string = hubToSpokePeering.id
