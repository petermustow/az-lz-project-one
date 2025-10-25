# Azure Hub and Spoke Landing Zone

A comprehensive Azure landing zone implementation based on the **Microsoft Well-Architected Framework**, featuring a hub-and-spoke network topology with integrated monitoring, management, and security best practices.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Methods](#deployment-methods)
- [Configuration](#configuration)
- [Post-Deployment](#post-deployment)
- [Monitoring and Management](#monitoring-and-management)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Well-Architected Framework Alignment](#well-architected-framework-alignment)

## Overview

This landing zone implements a **hub and spoke network topology** in Azure, providing a scalable, secure, and well-managed foundation for enterprise workloads. The solution uses **Azure Bicep** for infrastructure as code, ensuring repeatable and consistent deployments.

### What is Hub and Spoke?

The hub-and-spoke topology is a network architecture pattern where:

- **Hub**: A central virtual network containing shared services (Azure Firewall, VPN Gateway, Azure Bastion, monitoring)
- **Spokes**: Individual virtual networks for workloads, peered to the hub for centralized connectivity and management
- **Benefits**:
  - Centralized security and connectivity
  - Network isolation between workloads
  - Reduced management overhead
  - Cost optimization through shared resources

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        HUB VNET (10.0.0.0/16)               │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ Azure Firewall │  │  VPN Gateway │  │ Azure Bastion  │  │
│  └────────────────┘  └──────────────┘  └────────────────┘  │
│  ┌────────────────┐  ┌────────────────────────────────┐    │
│  │  Management    │  │   Shared Services              │    │
│  │  Subnet        │  │   Subnet                       │    │
│  └────────────────┘  └────────────────────────────────┘    │
└───────────────┬──────────────────────┬──────────────────────┘
                │                      │
        VNet Peering            VNet Peering
                │                      │
┌───────────────▼──────────────┐  ┌───▼──────────────────────┐
│   SPOKE 01 (10.1.0.0/16)     │  │  SPOKE 02 (10.2.0.0/16)  │
│  ┌────────┐ ┌────────┐       │  │  ┌────────┐ ┌────────┐  │
│  │  Web   │ │  App   │       │  │  │  Web   │ │  App   │  │
│  │  Tier  │ │  Tier  │       │  │  │  Tier  │ │  Tier  │  │
│  └────────┘ └────────┘       │  │  └────────┘ └────────┘  │
│  ┌────────────────────┐      │  │  ┌───────────────────┐  │
│  │    Data Tier       │      │  │  │   Data Tier       │  │
│  └────────────────────┘      │  │  └───────────────────┘  │
└──────────────────────────────┘  └──────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              MONITORING & MANAGEMENT                         │
│  ┌──────────────────┐  ┌────────────────────────────────┐  │
│  │  Log Analytics   │  │  Application Insights          │  │
│  │  Workspace       │  │                                │  │
│  └──────────────────┘  └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Components

#### Hub Virtual Network (10.0.0.0/16)
- **AzureFirewallSubnet (10.0.1.0/24)**: Azure Firewall for network traffic filtering
- **GatewaySubnet (10.0.2.0/27)**: VPN Gateway for hybrid connectivity
- **AzureBastionSubnet (10.0.3.0/26)**: Azure Bastion for secure VM access
- **ManagementSubnet (10.0.4.0/24)**: Management and jumpbox resources
- **SharedServicesSubnet (10.0.5.0/24)**: Shared services like DNS, AD

#### Spoke Virtual Networks
Each spoke includes:
- **WebTierSubnet**: Internet-facing applications
- **AppTierSubnet**: Application logic and services
- **DataTierSubnet**: Databases and data storage

#### Monitoring & Management
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring
- **Network Watcher**: Network diagnostics and monitoring
- **NSG Flow Logs**: Network security group traffic analysis
- **Azure Monitor Solutions**: Security, Updates, Change Tracking, VM Insights

## Features

### Network Security
- ✅ Azure Firewall with threat intelligence
- ✅ Network Security Groups (NSGs) on all subnets
- ✅ NSG Flow Logs with Traffic Analytics
- ✅ Network isolation between spokes
- ✅ Service Endpoints for Azure services
- ✅ Private Endpoint support

### Connectivity
- ✅ Hub-spoke VNet peering
- ✅ VPN Gateway for hybrid connectivity
- ✅ Azure Bastion for secure VM access
- ✅ Centralized routing through Azure Firewall

### Monitoring & Management
- ✅ Log Analytics workspace with 90-day retention
- ✅ Diagnostic settings on all resources
- ✅ Azure Monitor solutions (Security, Updates, Change Tracking, VM Insights)
- ✅ Application Insights for application monitoring
- ✅ Action Groups for alerting

### High Availability
- ✅ Zone-redundant Azure Firewall
- ✅ High availability for gateways
- ✅ Multi-region deployment support

### Cost Optimization
- ✅ Shared services in hub (Firewall, Bastion, Gateways)
- ✅ Right-sized SKUs with ability to scale
- ✅ Log Analytics daily cap to control costs
- ✅ Optional resource deployment flags

## Prerequisites

### Required Tools
- **Azure CLI** (version 2.50.0 or later)
  ```bash
  # Install on Linux/macOS
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

  # Install on Windows
  # Download from: https://aka.ms/installazurecliwindows
  ```

- **Azure Bicep**
  ```bash
  az bicep install
  az bicep upgrade
  ```

- **PowerShell 7+** (optional, for PowerShell deployment script)
  ```bash
  # Install on Linux/macOS
  wget https://aka.ms/install-powershell.sh
  chmod +x install-powershell.sh
  ./install-powershell.sh
  ```

- **jq** (for bash script, optional)
  ```bash
  # Install on Ubuntu/Debian
  sudo apt-get install jq

  # Install on macOS
  brew install jq
  ```

### Azure Permissions
- **Subscription Owner** or **Contributor** role at the subscription level
- Ability to create resource groups and resources
- Ability to register resource providers

### Azure Subscription
- Active Azure subscription
- Sufficient quota for resources (VNets, Public IPs, etc.)
- No conflicting IP address ranges

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd az-lz-project-one
```

### 2. Review and Update Parameters
Edit `bicep/main.bicepparam` to customize your deployment:

```bicep
// Basic configuration
param location = 'australiaeast'              // Your Azure region
param environment = 'dev'                     // dev, test, or prod
param organizationName = 'contoso'            // Your organization name

// Network configuration
param hubVnetAddressPrefix = '10.0.0.0/16'
param spokeVnetAddressPrefixes = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]

// Feature flags
param deployFirewall = true
param deployVpnGateway = true
param deployBastion = true
```

### 3. Deploy

#### Option A: Using Bash Script (Linux/macOS)
```bash
cd deployment-scripts
./deploy.sh
```

#### Option B: Using PowerShell Script (Windows/Linux/macOS)
```powershell
cd deployment-scripts
./deploy.ps1
```

#### Option C: Using Azure CLI Directly
```bash
az deployment sub create \
  --name hub-spoke-lz \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

### 4. Monitor Deployment
Deployment typically takes **30-45 minutes** due to gateway resources (VPN Gateway, Azure Firewall).

Monitor progress:
```bash
# List deployments
az deployment sub list --output table

# Show deployment details
az deployment sub show --name <deployment-name>
```

## Deployment Methods

### Method 1: Automated Deployment Scripts

#### Bash Script (`deploy.sh`)
Full-featured deployment script with validation and error handling.

**Usage:**
```bash
# Default deployment (dev environment, australiaeast)
./deploy.sh

# Production deployment
./deploy.sh -e prod -l australiaeast

# What-if deployment (preview changes)
./deploy.sh --what-if

# Custom subscription
./deploy.sh -s <subscription-id> -e prod

# Help
./deploy.sh --help
```

**Features:**
- Pre-deployment validation
- Resource provider registration
- Bicep compilation check
- What-if support
- Deployment output capture
- Colored output for better readability

#### PowerShell Script (`deploy.ps1`)
Cross-platform PowerShell deployment script.

**Usage:**
```powershell
# Default deployment
./deploy.ps1

# Production deployment
./deploy.ps1 -Environment prod -Location australiaeast

# What-if deployment
./deploy.ps1 -WhatIf

# Custom subscription
./deploy.ps1 -SubscriptionId <subscription-id> -Environment prod

# Help
Get-Help ./deploy.ps1 -Detailed
```

### Method 2: Azure CLI

#### Standard Deployment
```bash
az deployment sub create \
  --name hub-spoke-lz \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam \
  --parameters environment=prod
```

#### What-If Deployment
```bash
az deployment sub what-if \
  --name hub-spoke-lz \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

#### Override Parameters
```bash
az deployment sub create \
  --name hub-spoke-lz \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam \
  --parameters deployFirewall=false deployVpnGateway=false
```

### Method 3: Azure Portal

1. Navigate to **Deploy a custom template** in Azure Portal
2. Select **Build your own template in the editor**
3. Load `bicep/main.bicep` (compile to ARM template first: `az bicep build -f bicep/main.bicep`)
4. Configure parameters
5. Review and create

### Method 4: GitHub Actions / Azure DevOps

#### GitHub Actions Example
```yaml
name: Deploy Landing Zone

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Bicep
        run: |
          az deployment sub create \
            --name hub-spoke-lz-${{ github.run_number }} \
            --location australiaeast \
            --template-file bicep/main.bicep \
            --parameters bicep/main.bicepparam
```

#### Azure DevOps Pipeline Example
```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'Azure-ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az deployment sub create \
          --name hub-spoke-lz-$(Build.BuildNumber) \
          --location australiaeast \
          --template-file bicep/main.bicep \
          --parameters bicep/main.bicepparam
```

## Configuration

### Network Address Planning

Default IP address scheme:

| Network | CIDR | Purpose |
|---------|------|---------|
| Hub VNet | 10.0.0.0/16 | Central hub network |
| - Firewall Subnet | 10.0.1.0/24 | Azure Firewall |
| - Gateway Subnet | 10.0.2.0/27 | VPN Gateway |
| - Bastion Subnet | 10.0.3.0/26 | Azure Bastion |
| - Management Subnet | 10.0.4.0/24 | Management resources |
| - Shared Services | 10.0.5.0/24 | Shared services |
| Spoke 01 VNet | 10.1.0.0/16 | First workload spoke |
| - Web Tier | 10.1.1.0/24 | Web tier |
| - App Tier | 10.1.2.0/24 | Application tier |
| - Data Tier | 10.1.3.0/24 | Data tier |
| Spoke 02 VNet | 10.2.0.0/16 | Second workload spoke |
| - Web Tier | 10.2.1.0/24 | Web tier |
| - App Tier | 10.2.2.0/24 | Application tier |
| - Data Tier | 10.2.3.0/24 | Data tier |

**Important**: Ensure these ranges don't conflict with:
- On-premises networks (if using VPN Gateway)
- Other Azure VNets you plan to peer with
- VPN client address pool (default: 172.16.0.0/24)

### Adding More Spokes

To add additional spoke networks:

1. Edit `bicep/main.bicepparam`:
```bicep
param spokeCount = 3  // Increase number
param spokeVnetAddressPrefixes = [
  '10.1.0.0/16'
  '10.2.0.0/16'
  '10.3.0.0/16'  // Add new address space
]
```

2. Redeploy the template

### Customizing Security Rules

Edit `bicep/modules/shared/nsg.bicep` to add custom NSG rules or modify the spoke module to include application-specific rules.

### Firewall Policy

Default firewall rules are configured in `bicep/modules/shared/firewall.bicep`. Customize application and network rules as needed:

```bicep
// Example: Add custom application rule
{
  ruleType: 'ApplicationRule'
  name: 'AllowCustomApp'
  protocols: [
    {
      protocolType: 'Https'
      port: 443
    }
  ]
  sourceAddresses: ['*']
  targetFqdns: ['*.myapp.com']
}
```

## Post-Deployment

### Verify Deployment

```bash
# Check resource groups
az group list --query "[?starts_with(name, 'contoso-dev')]" --output table

# Check VNets
az network vnet list --output table

# Check peerings
az network vnet peering list --resource-group <hub-rg> --vnet-name <hub-vnet> --output table

# Check firewall
az network firewall list --output table
```

### Access Resources

#### Via Azure Bastion
1. Navigate to Azure Portal
2. Go to the VM you want to access
3. Click "Connect" → "Bastion"
4. Enter credentials

#### Via VPN (Point-to-Site)
1. Download VPN client from Azure Portal
2. Install and configure
3. Connect using Azure AD authentication

### Configure Additional Services

- **DNS**: Configure custom DNS servers in VNet settings
- **Azure Monitor Alerts**: Set up alerts based on your requirements
- **Azure Policy**: Apply governance policies to resource groups
- **Azure Backup**: Configure backup for VMs
- **Azure Site Recovery**: Set up disaster recovery

## Monitoring and Management

### Log Analytics Workspace

All resources send diagnostic logs to the centralized Log Analytics workspace.

**Access logs:**
```bash
# Get workspace ID
az monitor log-analytics workspace show \
  --resource-group <monitoring-rg> \
  --workspace-name <workspace-name> \
  --query customerId -o tsv
```

**Common queries:**

```kql
// NSG Flow Logs
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog"
| summarize count() by SrcIP_s, DestIP_s, DestPort_d

// Firewall logs
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| project TimeGenerated, msg_s

// Failed connections
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule"
| where msg_s contains "Deny"
| summarize count() by bin(TimeGenerated, 1h)
```

### Azure Monitor Workbooks

Pre-configured workbooks are available for:
- Network insights
- VM insights
- Security insights
- Azure Firewall monitoring

### Alerts

Configure alerts for:
- High CPU/memory usage
- Network anomalies
- Security events
- Backup failures
- Cost thresholds

## Security

### Network Security

1. **Network Segmentation**: Spokes are isolated from each other
2. **Centralized Firewall**: All internet traffic routes through Azure Firewall
3. **NSG Protection**: Every subnet has NSG with deny-by-default rules
4. **No Public IPs**: Workload VMs use Bastion or VPN for access
5. **Service Endpoints**: Secure access to Azure PaaS services

### Identity and Access

1. **Azure RBAC**: Use role-based access control
2. **Managed Identities**: For Azure resources to access services
3. **Azure AD Integration**: VPN uses Azure AD authentication
4. **Just-in-Time Access**: Configure JIT VM access

### Compliance

1. **Azure Policy**: Apply compliance policies
2. **Microsoft Defender for Cloud**: Enable for security recommendations
3. **Audit Logs**: All actions logged to Log Analytics
4. **Encryption**: Enable encryption at rest and in transit

### Security Checklist

- [ ] Enable Microsoft Defender for Cloud
- [ ] Configure Azure Policy for compliance
- [ ] Set up Azure AD Conditional Access
- [ ] Enable MFA for all users
- [ ] Configure JIT VM access
- [ ] Review and approve NSG rules
- [ ] Review firewall rules regularly
- [ ] Enable Azure DDoS Protection (if required)
- [ ] Configure Azure Key Vault for secrets
- [ ] Set up security alerts

## Cost Optimization

### Estimated Monthly Costs (dev environment)

| Resource | SKU | Est. Cost (AUD) |
|----------|-----|-----------------|
| Hub VNet | Standard | $0 |
| Spoke VNets (2) | Standard | $0 |
| Azure Firewall | Standard | $1,200 |
| VPN Gateway | VpnGw1 | $200 |
| Azure Bastion | Standard | $175 |
| Log Analytics | 10GB/day | $30 |
| **Total** | | **~$1,605/month** |

### Cost Reduction Strategies

1. **Dev/Test Environments**:
   - Disable firewall: `param deployFirewall = false`
   - Disable VPN Gateway: `param deployVpnGateway = false`
   - Use Basic Bastion: Modify SKU in bastion.bicep
   - Stop resources during off-hours

2. **Production Optimization**:
   - Right-size VPN Gateway SKU
   - Use Azure Firewall Manager for multi-hub scenarios
   - Implement auto-shutdown for dev VMs
   - Use Azure Hybrid Benefit for VMs

3. **Monitoring Costs**:
   - Adjust Log Analytics retention (default: 90 days)
   - Set daily data cap on Log Analytics
   - Archive old logs to Storage Account

## Troubleshooting

### Common Issues

#### 1. Deployment Timeout
**Issue**: Gateway deployments taking too long
**Solution**: This is normal. VPN Gateway can take 30-45 minutes to deploy.

#### 2. IP Address Conflicts
**Issue**: Address space overlaps with existing networks
**Solution**: Update `hubVnetAddressPrefix` and `spokeVnetAddressPrefixes` in parameters file

#### 3. Resource Provider Not Registered
**Issue**: `The subscription is not registered to use namespace 'Microsoft.Network'`
**Solution**: Run deployment scripts which auto-register, or manually:
```bash
az provider register --namespace Microsoft.Network --wait
```

#### 4. Insufficient Permissions
**Issue**: Cannot create resources
**Solution**: Ensure you have Contributor or Owner role at subscription level

#### 5. VNet Peering Failed
**Issue**: Peering not established between hub and spoke
**Solution**: Check if VNets exist and address spaces don't overlap

### Validation Commands

```bash
# Check deployment status
az deployment sub show --name <deployment-name>

# View deployment errors
az deployment sub operation list --name <deployment-name>

# Test network connectivity (from a VM)
# Install Network Watcher VM extension, then:
az network watcher test-connectivity \
  --resource-group <rg> \
  --source-resource <vm-id> \
  --dest-address <destination-ip> \
  --dest-port 443
```

### Getting Help

- **Azure Support**: Open a support ticket in Azure Portal
- **Documentation**: https://docs.microsoft.com/azure/
- **Community**: https://aka.ms/AzureCommunity

## Well-Architected Framework Alignment

This landing zone is designed according to the five pillars of the [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/):

### 1. Cost Optimization
- ✅ Shared services model reduces costs
- ✅ Right-sized SKUs with scaling options
- ✅ Resource tagging for cost allocation
- ✅ Optional deployment flags to reduce costs in non-prod
- ✅ Log Analytics daily cap

### 2. Operational Excellence
- ✅ Infrastructure as Code (Bicep)
- ✅ Centralized monitoring and logging
- ✅ Automated deployment scripts
- ✅ Diagnostic settings on all resources
- ✅ Resource naming conventions
- ✅ Comprehensive documentation

### 3. Performance Efficiency
- ✅ Zone-redundant resources for high availability
- ✅ Optimized network routing through hub
- ✅ Service endpoints for Azure services
- ✅ Scalable spoke model

### 4. Reliability
- ✅ Multi-region deployment support
- ✅ Zone-redundant Azure Firewall
- ✅ High-availability gateways
- ✅ Network isolation
- ✅ Redundant network paths

### 5. Security
- ✅ Defense in depth (Firewall, NSGs, Bastion)
- ✅ Network segmentation
- ✅ Centralized logging and monitoring
- ✅ Azure AD integration
- ✅ No public IPs on workload resources
- ✅ Service endpoints and private endpoints support
- ✅ Threat intelligence enabled on firewall

## Project Structure

```
az-lz-project-one/
├── bicep/
│   ├── main.bicep                          # Main entry point
│   ├── main.bicepparam                     # Parameters file
│   └── modules/
│       ├── hub/
│       │   └── hub.bicep                   # Hub VNet module
│       ├── spoke/
│       │   ├── spoke.bicep                 # Spoke VNet module
│       │   └── peering.bicep               # VNet peering module
│       ├── monitoring/
│       │   └── monitoring.bicep            # Monitoring & management
│       └── shared/
│           ├── firewall.bicep              # Azure Firewall
│           ├── bastion.bicep               # Azure Bastion
│           ├── vpngateway.bicep            # VPN Gateway
│           └── nsg.bicep                   # Network Security Groups
├── deployment-scripts/
│   ├── deploy.sh                           # Bash deployment script
│   └── deploy.ps1                          # PowerShell deployment script
├── docs/
│   └── architecture.md                     # Detailed architecture documentation
└── README.md                               # This file
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Hub-spoke network topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)

## Support

For issues and questions:
- Create an issue in the repository
- Contact the Platform Engineering team
- Azure Support: https://azure.microsoft.com/support/

---

**Version**: 1.0.0
**Last Updated**: 2025-10-25
**Maintained by**: Platform Engineering Team
