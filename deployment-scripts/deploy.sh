#!/bin/bash

#######################################
# Hub and Spoke Landing Zone Deployment
# Based on Microsoft Well-Architected Framework
#######################################

set -e

# Default values
LOCATION="australiaeast"
ENVIRONMENT="dev"
SUBSCRIPTION_ID=""
WHAT_IF=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Help function
function show_help {
    echo ""
    echo "Usage: ./deploy.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -l, --location LOCATION       Azure region (default: australiaeast)"
    echo "  -e, --environment ENV         Environment: dev, test, prod (default: dev)"
    echo "  -s, --subscription ID         Azure subscription ID"
    echo "  -w, --what-if                 Preview changes without deploying"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh"
    echo "  ./deploy.sh -e prod -l australiaeast"
    echo "  ./deploy.sh --what-if"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -w|--what-if)
            WHAT_IF=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be dev, test, or prod${NC}"
    exit 1
fi

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_PATH="$(dirname "$SCRIPT_DIR")/bicep"
MAIN_BICEP_FILE="$BICEP_PATH/main.bicep"
PARAMETERS_FILE="$BICEP_PATH/main.bicepparam"
DEPLOYMENT_NAME="hub-spoke-lz-$(date +%Y%m%d-%H%M%S)"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Hub and Spoke Landing Zone Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv)
echo -e "${GREEN}Azure CLI Version: $AZ_VERSION${NC}"

# Check if logged in
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Initiating login...${NC}"
    az login
fi

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo -e "${YELLOW}Setting subscription to: $SUBSCRIPTION_ID${NC}"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Get current subscription info
CURRENT_SUB=$(az account show)
SUB_NAME=$(echo "$CURRENT_SUB" | jq -r '.name')
SUB_ID=$(echo "$CURRENT_SUB" | jq -r '.id')

echo -e "${GREEN}Deploying to subscription: $SUB_NAME ($SUB_ID)${NC}"
echo -e "${GREEN}Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}Location: $LOCATION${NC}"
echo ""

# Register required resource providers
echo -e "${YELLOW}Registering required resource providers...${NC}"
PROVIDERS=(
    "Microsoft.Network"
    "Microsoft.Compute"
    "Microsoft.Storage"
    "Microsoft.OperationalInsights"
    "Microsoft.Insights"
    "Microsoft.Security"
    "Microsoft.OperationsManagement"
)

for PROVIDER in "${PROVIDERS[@]}"; do
    STATUS=$(az provider show --namespace "$PROVIDER" --query "registrationState" -o tsv)
    if [ "$STATUS" != "Registered" ]; then
        echo -e "${YELLOW}  Registering $PROVIDER...${NC}"
        az provider register --namespace "$PROVIDER" --wait
    else
        echo -e "${GREEN}  $PROVIDER is already registered${NC}"
    fi
done

echo ""

# Validate Bicep files
echo -e "${YELLOW}Validating Bicep templates...${NC}"
if az bicep build --file "$MAIN_BICEP_FILE"; then
    echo -e "${GREEN}Bicep validation successful!${NC}"
else
    echo -e "${RED}Bicep validation failed!${NC}"
    exit 1
fi

echo ""

# Deploy or what-if
if [ "$WHAT_IF" = true ]; then
    echo -e "${YELLOW}Running what-if deployment...${NC}"
    az deployment sub what-if \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETERS_FILE" \
        --parameters location="$LOCATION" environment="$ENVIRONMENT"
else
    echo -e "${YELLOW}Starting deployment...${NC}"
    echo -e "${CYAN}Deployment name: $DEPLOYMENT_NAME${NC}"
    echo ""
    echo -e "${YELLOW}NOTE: This deployment may take 30-45 minutes to complete due to gateway resources.${NC}"
    echo ""

    if DEPLOYMENT=$(az deployment sub create \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file "$MAIN_BICEP_FILE" \
        --parameters "$PARAMETERS_FILE" \
        --parameters location="$LOCATION" environment="$ENVIRONMENT" \
        --output json); then

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Deployment completed successfully!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${CYAN}Deployment Outputs:${NC}"
        echo "$DEPLOYMENT" | jq '.properties.outputs'
        echo ""

        # Save outputs to file
        OUTPUT_FILE="$SCRIPT_DIR/deployment-outputs-$(date +%Y%m%d-%H%M%S).json"
        echo "$DEPLOYMENT" | jq '.properties.outputs' > "$OUTPUT_FILE"
        echo -e "${GREEN}Outputs saved to: $OUTPUT_FILE${NC}"
    else
        echo -e "${RED}Deployment failed!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}Deployment script completed.${NC}"
