# Azure Hub and Spoke Landing Zone - Architecture Documentation

## Executive Summary

This document provides detailed architectural documentation for the Azure hub and spoke landing zone implementation. The design follows Microsoft's Well-Architected Framework principles and provides a secure, scalable, and well-managed foundation for enterprise workloads in Azure.

## Architecture Overview

### Design Principles

1. **Security by Default**: All networks are isolated with deny-by-default NSG rules
2. **Centralized Management**: Shared services consolidated in the hub
3. **Scalability**: Easy to add new spokes for workloads
4. **Monitoring**: Comprehensive logging and monitoring across all resources
5. **Cost Optimization**: Shared resources minimize duplication and costs

### Hub and Spoke Pattern

The hub-and-spoke model is a networking topology where:

- **Hub**: Contains shared/common services used by multiple workloads
- **Spokes**: Isolated workload environments that consume hub services
- **Connectivity**: VNet peering connects spokes to hub (no spoke-to-spoke direct connection)

## Network Architecture

### Hub Virtual Network

**Address Space**: 10.0.0.0/16

#### Subnets

| Subnet Name | Address Prefix | Purpose | Special Requirements |
|-------------|----------------|---------|---------------------|
| AzureFirewallSubnet | 10.0.1.0/24 | Azure Firewall | Must be named "AzureFirewallSubnet", minimum /26 |
| GatewaySubnet | 10.0.2.0/27 | VPN/ExpressRoute Gateway | Must be named "GatewaySubnet", minimum /27 |
| AzureBastionSubnet | 10.0.3.0/26 | Azure Bastion | Must be named "AzureBastionSubnet", minimum /26 |
| ManagementSubnet | 10.0.4.0/24 | Jumpboxes, management VMs | NSG required |
| SharedServicesSubnet | 10.0.5.0/24 | DNS, AD, shared services | NSG required |

### Spoke Virtual Networks

Each spoke follows a three-tier architecture pattern:

**Example Spoke 01**: 10.1.0.0/16

| Subnet Name | Address Prefix | Purpose | NSG Rules |
|-------------|----------------|---------|-----------|
| WebTierSubnet | 10.1.1.0/24 | Internet-facing web servers | Allow 80/443 from Internet |
| AppTierSubnet | 10.1.2.0/24 | Application logic | Allow traffic from Web tier |
| DataTierSubnet | 10.1.3.0/24 | Databases | Allow 1433/3306/5432 from App tier |

### VNet Peering

- **Hub-to-Spoke**: AllowGatewayTransit enabled
- **Spoke-to-Hub**: UseRemoteGateways enabled (when VPN Gateway exists)
- **Spoke-to-Spoke**: No direct peering (traffic routes through hub)

## Core Services

### Azure Firewall

**SKU**: Standard (configurable to Premium)
**Features**:
- Threat intelligence-based filtering (Alert mode)
- Application rules for FQDN filtering
- Network rules for IP/port filtering
- DNS proxy enabled
- Availability Zones: 1, 2, 3 (zone-redundant)

**Default Rules**:
- Allow Azure services (Monitor, Backup)
- Allow Windows Update
- Allow access to *.azure.com, *.microsoft.com

**Use Cases**:
- Centralized egress filtering
- Spoke-to-spoke communication
- Application-level filtering
- Threat detection

### Azure Bastion

**SKU**: Standard
**Features**:
- Tunneling enabled (native client support)
- File copy enabled
- IP-based connection enabled
- No public IPs required on VMs

**Use Cases**:
- Secure RDP/SSH to VMs
- No need for jumpbox VMs
- Session recording capabilities
- Compliance with security policies

### VPN Gateway

**SKU**: VpnGw1 (configurable)
**Type**: Route-based VPN
**Features**:
- Point-to-Site VPN (Azure AD authentication)
- Site-to-Site VPN capability
- BGP support (optional)
- Active-passive configuration (upgradeable to active-active)

**VPN Client Configuration**:
- Address Pool: 172.16.0.0/24
- Protocols: OpenVPN, IKEv2
- Authentication: Azure AD

**Use Cases**:
- Remote user connectivity
- Hybrid connectivity to on-premises
- Branch office connectivity

### Network Security Groups (NSGs)

#### NSG Types and Rules

**Web Tier NSG**:
```
Priority 100: Allow HTTPS (443) from Internet
Priority 110: Allow HTTP (80) from Internet
Priority 4096: Deny All Inbound
```

**App Tier NSG**:
```
Priority 100: Allow traffic from VirtualNetwork
Priority 4096: Deny All Inbound
```

**Data Tier NSG**:
```
Priority 100: Allow 1433,3306,5432 from VirtualNetwork
Priority 4096: Deny All Inbound
```

**Management NSG**:
```
Priority 100: Allow RDP (3389) from VirtualNetwork
Priority 110: Allow SSH (22) from VirtualNetwork
Priority 4096: Deny All Inbound
```

#### NSG Flow Logs

All NSGs are configured with:
- Flow logging enabled
- Log Analytics integration
- Traffic Analytics enabled (60-minute interval)
- 90-day retention
- Version 2 format (JSON)

## Monitoring and Management

### Log Analytics Workspace

**Configuration**:
- SKU: PerGB2018 (pay-as-you-go)
- Retention: 90 days
- Daily cap: 10 GB
- Location: Same as resources

**Solutions Enabled**:
1. **Security**: Security events and alerts
2. **Updates**: Update management for VMs
3. **Change Tracking**: Track configuration changes
4. **VM Insights**: Performance and health monitoring
5. **Network Monitoring**: Network performance and topology

**Data Sources**:
- Azure Firewall logs
- NSG Flow Logs
- Azure Bastion logs
- VPN Gateway logs
- Diagnostic settings from all resources

### Application Insights

**Configuration**:
- Workspace-based (integrated with Log Analytics)
- Retention: 90 days
- Type: Web application monitoring

**Use Cases**:
- Application performance monitoring
- Dependency tracking
- Exception tracking
- Custom telemetry

### Azure Monitor

**Action Groups**:
- Email notifications to platform team
- Common alert schema enabled
- Extensible to SMS, webhooks, Logic Apps

**Alert Types**:
- Metric alerts (CPU, memory, network)
- Log alerts (security events, errors)
- Activity log alerts (resource changes)

### Network Watcher

**Capabilities**:
- Connection Monitor
- Network Performance Monitor
- Packet Capture
- NSG diagnostics
- Next hop analysis
- Topology visualization

## Traffic Flow Patterns

### Internet Inbound Traffic

```
Internet → Azure Firewall Public IP → Firewall Rules →
Spoke Web Tier → Spoke App Tier → Spoke Data Tier
```

### Internet Outbound Traffic

```
Spoke → Hub (via peering) → Azure Firewall → Internet
```

### Spoke-to-Spoke Traffic

```
Spoke 01 → Hub → Azure Firewall → Hub → Spoke 02
```

### Management Access

```
Administrator → VPN Gateway / Bastion → Hub Management Subnet → Spoke Resources
```

### Hybrid Connectivity

```
On-Premises → VPN Gateway → Hub → Spoke (via peering)
```

## Security Controls

### Network Layer

1. **Perimeter Security**:
   - Azure Firewall for ingress/egress filtering
   - Public IPs only on shared services (Firewall, Bastion, VPN Gateway)
   - DDoS protection (optional, configurable)

2. **Network Segmentation**:
   - Hub isolated from spokes (controlled via peering)
   - Spokes isolated from each other
   - Tiers within spokes isolated (NSGs)

3. **Traffic Filtering**:
   - NSG rules on all subnets
   - Azure Firewall application and network rules
   - Service endpoints for Azure PaaS services

### Identity Layer

1. **Authentication**:
   - Azure AD for VPN authentication
   - Managed identities for Azure resources
   - No local credentials stored

2. **Authorization**:
   - Azure RBAC for resource access
   - Network isolation as defense in depth
   - Just-in-Time (JIT) access for VMs

### Application Layer

1. **Service Endpoints**:
   - Storage accounts
   - Key Vault
   - SQL Database
   - Restricted to specific subnets

2. **Private Endpoints**:
   - Support for PaaS services
   - No public internet exposure
   - Private DNS integration

### Data Layer

1. **Encryption**:
   - TLS/SSL for data in transit
   - Azure Storage encryption at rest
   - Disk encryption for VMs

2. **Secrets Management**:
   - Azure Key Vault integration
   - Managed identity access
   - No hardcoded secrets

## High Availability and Disaster Recovery

### Availability Zones

Components deployed across zones:
- Azure Firewall (zones 1, 2, 3)
- VPN Gateway (zone-redundant SKU available)
- Load balancers (configurable)

### Redundancy

1. **Network Level**:
   - Multiple VPN tunnels (site-to-site)
   - ExpressRoute with VPN backup (optional)
   - Multi-region VNet peering (configurable)

2. **Service Level**:
   - Zone-redundant services where available
   - Load balancing across availability zones
   - Auto-healing capabilities

### Backup and Recovery

1. **Azure Backup**:
   - VM backup to Recovery Services Vault
   - Integrated with Log Analytics
   - Policy-based retention

2. **Azure Site Recovery**:
   - DR to secondary region
   - Automated failover
   - Regular DR drills

## Scalability

### Horizontal Scaling

1. **Adding Spokes**:
   - Increment `spokeCount` parameter
   - Add address space to `spokeVnetAddressPrefixes`
   - Automatic peering configuration

2. **Adding Subnets**:
   - Modify spoke or hub Bicep templates
   - Define NSG rules
   - Redeploy

### Vertical Scaling

1. **Gateway SKUs**:
   - VPN Gateway: VpnGw1 → VpnGw2 → VpnGw3
   - Azure Firewall: Standard → Premium

2. **Log Analytics**:
   - Increase daily cap as needed
   - Adjust retention policies
   - Archive to storage account

### Multi-Region

To deploy in multiple regions:
1. Deploy separate landing zone per region
2. Connect via Global VNet Peering
3. Use Azure Front Door or Traffic Manager
4. Implement Azure Firewall Manager for centralized policies

## Compliance and Governance

### Azure Policy

Recommended policies:
- Enforce NSG on all subnets
- Require diagnostic settings
- Restrict VM SKUs
- Enforce tag requirements
- Geo-fencing for data residency

### Resource Tagging

Standard tags applied:
```bicep
{
  Environment: 'dev|test|prod'
  ManagedBy: 'Bicep'
  Framework: 'Well-Architected'
  Architecture: 'Hub-Spoke'
  CostCenter: 'IT-Infrastructure'
  Owner: 'Platform Team'
}
```

### Regulatory Compliance

Frameworks supported:
- ISO 27001
- SOC 2
- PCI DSS (with additional controls)
- HIPAA (with additional controls)
- GDPR

## Cost Management

### Cost Drivers

1. **High Cost Items**:
   - Azure Firewall: ~$1,200/month
   - VPN Gateway: ~$200/month
   - Azure Bastion: ~$175/month

2. **Variable Costs**:
   - Log Analytics ingestion
   - Data transfer (egress)
   - VPN Gateway bandwidth

### Optimization Strategies

1. **Non-Production Environments**:
   - Deploy minimal configuration (no Firewall/VPN)
   - Use NSGs and Azure Bastion only
   - Implement auto-shutdown

2. **Production Environments**:
   - Right-size gateway SKUs
   - Use reservations for predictable workloads
   - Archive logs to cheaper storage

3. **Monitoring Costs**:
   - Set Log Analytics daily cap
   - Optimize log collection
   - Use sampling for Application Insights

## Deployment Considerations

### Pre-Deployment

1. **IP Address Planning**:
   - Ensure no conflicts with existing networks
   - Plan for growth
   - Document address allocations

2. **Naming Conventions**:
   - Consistent resource naming
   - Include environment and region
   - Follow organization standards

3. **Prerequisites**:
   - Subscription quotas
   - Resource provider registration
   - Required permissions

### Deployment Order

1. Monitoring resource group and Log Analytics
2. Hub resource group and VNet
3. NSGs and security resources
4. Azure Firewall (30-45 minutes)
5. VPN Gateway (30-45 minutes)
6. Azure Bastion (5-10 minutes)
7. Spoke resource groups and VNets
8. VNet peerings

### Post-Deployment

1. **Validation**:
   - Test VNet peering
   - Verify firewall rules
   - Test Bastion connectivity
   - Check monitoring data flow

2. **Configuration**:
   - Configure custom DNS
   - Add firewall rules as needed
   - Set up alerts
   - Configure backup policies

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Peering not working | Address space overlap | Change spoke address ranges |
| Can't access VM | NSG blocking | Review NSG rules, use Network Watcher |
| High egress costs | Unoptimized data transfer | Review traffic patterns, use CDN |
| Deployment timeout | Gateway creation | This is normal, wait 30-45 minutes |
| VPN connection fails | Authentication issue | Verify Azure AD configuration |

### Diagnostic Tools

1. **Network Watcher**:
   - IP flow verify
   - Next hop
   - Connection troubleshoot
   - Packet capture

2. **Log Analytics Queries**:
   - NSG flow analysis
   - Firewall deny logs
   - Connection failures
   - Performance metrics

3. **Azure Monitor**:
   - Metrics explorer
   - Workbooks
   - Alert history

## Future Enhancements

### Planned Improvements

1. **Network**:
   - Azure Virtual WAN integration
   - ExpressRoute connectivity
   - Azure Route Server

2. **Security**:
   - Azure Firewall Premium
   - Microsoft Defender for Cloud integration
   - Azure DDoS Protection Standard

3. **Management**:
   - Azure Automation for maintenance
   - Update Management integration
   - Inventory and change tracking

4. **Multi-Region**:
   - Global VNet peering
   - Azure Firewall Manager
   - Cross-region load balancing

### Extensibility

The architecture supports:
- Additional spoke networks
- ExpressRoute circuits
- Third-party NVAs
- Application delivery controllers
- Web Application Firewall (WAF)

## References

### Microsoft Documentation

- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Hub-spoke topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall architecture](https://docs.microsoft.com/azure/architecture/example-scenario/firewalls/)
- [Network security best practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)

### Azure Services

- [Azure Virtual Network](https://docs.microsoft.com/azure/virtual-network/)
- [Azure Firewall](https://docs.microsoft.com/azure/firewall/)
- [Azure Bastion](https://docs.microsoft.com/azure/bastion/)
- [VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [Network Security Groups](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Log Analytics](https://docs.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-25
**Author**: Platform Engineering Team
**Review Cycle**: Quarterly
