// =========================================
// Hub and Spoke Landing Zone - Parameters File
// =========================================

using './main.bicep'

// Azure region for deployment
param location = 'australiaeast'

// Environment configuration
param environment = 'dev'

// Organization name for resource naming
param organizationName = 'contoso'

// Hub VNet Configuration
param hubVnetAddressPrefix = '10.0.0.0/16'

// Feature flags
param deployFirewall = true
param deployVpnGateway = true
param deployBastion = true

// Spoke configuration
param spokeCount = 2
param spokeVnetAddressPrefixes = [
  '10.1.0.0/16'  // Spoke 01 - Production workloads
  '10.2.0.0/16'  // Spoke 02 - Development workloads
]

// Resource tags
param tags = {
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Framework: 'Well-Architected'
  Architecture: 'Hub-Spoke'
  CostCenter: 'IT-Infrastructure'
  Owner: 'Platform Team'
}
