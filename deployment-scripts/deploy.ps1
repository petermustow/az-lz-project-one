<#
.SYNOPSIS
    Deploys the Hub and Spoke Landing Zone to Azure

.DESCRIPTION
    This script deploys a hub and spoke landing zone architecture based on
    Microsoft Well-Architected Framework best practices using Azure Bicep.

.PARAMETER Location
    Azure region for deployment (default: australiaeast)

.PARAMETER Environment
    Environment name: dev, test, or prod (default: dev)

.PARAMETER SubscriptionId
    Azure subscription ID (optional - uses current context if not provided)

.PARAMETER WhatIf
    Performs a what-if deployment to preview changes without deploying

.EXAMPLE
    .\deploy.ps1

.EXAMPLE
    .\deploy.ps1 -Environment prod -Location australiaeast

.EXAMPLE
    .\deploy.ps1 -WhatIf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "australiaeast",

    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment = "dev",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Error handling
$ErrorActionPreference = "Stop"

# Script variables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$bicepPath = Join-Path (Split-Path -Parent $scriptPath) "bicep"
$mainBicepFile = Join-Path $bicepPath "main.bicep"
$parametersFile = Join-Path $bicepPath "main.bicepparam"
$deploymentName = "hub-spoke-lz-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Hub and Spoke Landing Zone Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI Version: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Check if logged in
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$loginStatus = az account show 2>$null
if (-not $loginStatus) {
    Write-Host "Not logged in to Azure. Initiating login..." -ForegroundColor Yellow
    az login
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription to: $SubscriptionId" -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
}

# Get current subscription info
$currentSub = az account show | ConvertFrom-Json
Write-Host "Deploying to subscription: $($currentSub.name) ($($currentSub.id))" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host ""

# Register required resource providers
Write-Host "Registering required resource providers..." -ForegroundColor Yellow
$providers = @(
    "Microsoft.Network",
    "Microsoft.Compute",
    "Microsoft.Storage",
    "Microsoft.OperationalInsights",
    "Microsoft.Insights",
    "Microsoft.Security",
    "Microsoft.OperationsManagement"
)

foreach ($provider in $providers) {
    $status = az provider show --namespace $provider --query "registrationState" -o tsv
    if ($status -ne "Registered") {
        Write-Host "  Registering $provider..." -ForegroundColor Yellow
        az provider register --namespace $provider --wait
    }
    else {
        Write-Host "  $provider is already registered" -ForegroundColor Green
    }
}

Write-Host ""

# Validate Bicep files
Write-Host "Validating Bicep templates..." -ForegroundColor Yellow
try {
    az bicep build --file $mainBicepFile
    Write-Host "Bicep validation successful!" -ForegroundColor Green
}
catch {
    Write-Error "Bicep validation failed: $_"
    exit 1
}

Write-Host ""

# Deploy or what-if
if ($WhatIf) {
    Write-Host "Running what-if deployment..." -ForegroundColor Yellow
    az deployment sub what-if `
        --name $deploymentName `
        --location $Location `
        --template-file $mainBicepFile `
        --parameters $parametersFile `
        --parameters location=$Location environment=$Environment
}
else {
    Write-Host "Starting deployment..." -ForegroundColor Yellow
    Write-Host "Deployment name: $deploymentName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NOTE: This deployment may take 30-45 minutes to complete due to gateway resources." -ForegroundColor Yellow
    Write-Host ""

    $deployment = az deployment sub create `
        --name $deploymentName `
        --location $Location `
        --template-file $mainBicepFile `
        --parameters $parametersFile `
        --parameters location=$Location environment=$Environment `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Deployment Outputs:" -ForegroundColor Cyan
        $deployment.properties.outputs | ConvertTo-Json -Depth 10
        Write-Host ""

        # Save outputs to file
        $outputFile = Join-Path $scriptPath "deployment-outputs-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $deployment.properties.outputs | ConvertTo-Json -Depth 10 | Out-File $outputFile
        Write-Host "Outputs saved to: $outputFile" -ForegroundColor Green
    }
    else {
        Write-Error "Deployment failed!"
        exit 1
    }
}

Write-Host ""
Write-Host "Deployment script completed." -ForegroundColor Cyan
