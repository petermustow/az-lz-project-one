// =========================================
// Hub and Spoke Landing Zone - Main Template
// Based on Microsoft Well-Architected Framework
// =========================================

targetScope = 'subscription'

// =========================================
// Parameters
// =========================================

@description('Azure region for the deployment')
param location string = 'australiaeast'

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Organization name for resource naming')
param organizationName string = 'contoso'

@description('Hub VNet address prefix')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Deploy Azure Firewall')
param deployFirewall bool = true

@description('Deploy VPN Gateway')
param deployVpnGateway bool = true

@description('Deploy Azure Bastion')
param deployBastion bool = true

@description('Number of spoke networks to deploy')
param spokeCount int = 2

@description('Array of spoke VNet address prefixes')
param spokeVnetAddressPrefixes array = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  ManagedBy: 'Bicep'
  Framework: 'Well-Architected'
  Architecture: 'Hub-Spoke'
}

// =========================================
// Variables
// =========================================

var namingPrefix = '${organizationName}-${environment}'
var hubResourceGroupName = '${namingPrefix}-hub-rg'
var monitoringResourceGroupName = '${namingPrefix}-monitoring-rg'
var spokeResourceGroupNamePrefix = '${namingPrefix}-spoke'

// =========================================
// Resource Groups
// =========================================

// Hub Resource Group
resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubResourceGroupName
  location: location
  tags: tags
}

// Monitoring Resource Group
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: monitoringResourceGroupName
  location: location
  tags: tags
}

// Spoke Resource Groups
resource spokeResourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for i in range(0, spokeCount): {
  name: '${spokeResourceGroupNamePrefix}-${padLeft(i + 1, 2, '0')}-rg'
  location: location
  tags: tags
}]

// =========================================
// Monitoring and Management Module
// =========================================

module monitoring 'modules/monitoring/monitoring.bicep' = {
  scope: monitoringResourceGroup
  name: 'monitoring-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    tags: tags
  }
}

// =========================================
// Hub Network Module
// =========================================

module hub 'modules/hub/hub.bicep' = {
  scope: hubResourceGroup
  name: 'hub-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    vnetAddressPrefix: hubVnetAddressPrefix
    deployFirewall: deployFirewall
    deployVpnGateway: deployVpnGateway
    deployBastion: deployBastion
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
}

// =========================================
// Spoke Network Modules
// =========================================

module spokes 'modules/spoke/spoke.bicep' = [for i in range(0, spokeCount): {
  scope: spokeResourceGroups[i]
  name: 'spoke-${padLeft(i + 1, 2, '0')}-deployment'
  params: {
    location: location
    namingPrefix: namingPrefix
    spokeNumber: i + 1
    vnetAddressPrefix: spokeVnetAddressPrefixes[i]
    hubVnetId: hub.outputs.hubVnetId
    hubVnetName: hub.outputs.hubVnetName
    hubResourceGroupName: hubResourceGroupName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
  dependsOn: [
    hub
  ]
}]

// =========================================
// Outputs
// =========================================

output hubVnetId string = hub.outputs.hubVnetId
output hubVnetName string = hub.outputs.hubVnetName
output hubResourceGroupName string = hubResourceGroupName
output monitoringResourceGroupName string = monitoringResourceGroupName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output spokeVnetIds array = [for i in range(0, spokeCount): spokes[i].outputs.spokeVnetId]
output firewallPrivateIp string = deployFirewall ? hub.outputs.firewallPrivateIp : ''
output bastionName string = deployBastion ? hub.outputs.bastionName : ''
