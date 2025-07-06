#!/bin/bash
# Deployment script for EKS infrastructure with environment-specific configurations

set -e

# Default values
ENVIRONMENT="testing"
ACTION="plan"
AWS_PROFILE="terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 -e <environment> -a <action> [-p <aws_profile>]"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment: testing, staging, production"
    echo "  -a, --action        Action: plan, apply, destroy"
    echo "  -p, --profile       AWS profile (default: terraform)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e testing -a plan"
    echo "  $0 -e production -a apply"
    echo "  $0 -e staging -a destroy"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(testing|staging|production)$ ]]; then
    echo -e "${RED}Error: Environment must be one of: testing, staging, production${NC}"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo -e "${RED}Error: Action must be one of: plan, apply, destroy${NC}"
    exit 1
fi

# Set AWS profile
export AWS_PROFILE="$AWS_PROFILE"

echo -e "${BLUE}=== EKS Infrastructure Deployment ===${NC}"
echo -e "${BLUE}Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "${BLUE}Action: ${GREEN}$ACTION${NC}"
echo -e "${BLUE}AWS Profile: ${GREEN}$AWS_PROFILE${NC}"
echo ""

# Check if tfvars file exists
TFVARS_FILE="terraform.tfvars.$ENVIRONMENT"
if [[ ! -f "$TFVARS_FILE" ]]; then
    echo -e "${RED}Error: Configuration file $TFVARS_FILE not found${NC}"
    exit 1
fi

# Display cost implications and architecture details
echo -e "${YELLOW}=== Cost & Architecture Overview ===${NC}"
case $ENVIRONMENT in
    testing)
        echo -e "${GREEN}✓ NAT Gateways: DISABLED - Saves ~$135/month${NC}"
        echo -e "${GREEN}✓ EKS Nodes: PUBLIC SUBNETS - Internet access via IGW${NC}"
        echo -e "${BLUE}ℹ Perfect for development and testing with full connectivity${NC}"
        ;;
    staging)
        echo -e "${YELLOW}⚠ NAT Gateways: 1 ENABLED - Costs ~$45/month${NC}"
        echo -e "${YELLOW}⚠ EKS Nodes: PRIVATE SUBNETS - Internet access via NAT${NC}"
        echo -e "${GREEN}✓ Saves $90/month compared to production${NC}"
        ;;
    production)
        echo -e "${RED}💰 NAT Gateways: 3 ENABLED - Costs ~$135/month${NC}"
        echo -e "${RED}💰 EKS Nodes: PRIVATE SUBNETS - High availability${NC}"
        echo -e "${GREEN}✓ High availability across all AZs${NC}"
        ;;
esac
echo ""

# Confirmation for destructive actions
if [[ "$ACTION" == "apply" || "$ACTION" == "destroy" ]]; then
    echo -e "${YELLOW}Are you sure you want to $ACTION the $ENVIRONMENT environment? (y/N)${NC}"
    read -r confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled${NC}"
        exit 0
    fi
fi

# Initialize Terraform if needed
if [[ ! -d ".terraform" ]]; then
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init
fi

# Run Terraform command
echo -e "${BLUE}Running terraform $ACTION...${NC}"
case $ACTION in
    plan)
        terraform plan -var-file="$TFVARS_FILE"
        ;;
    apply)
        terraform apply -var-file="$TFVARS_FILE" -auto-approve
        echo -e "${GREEN}✓ Deployment completed successfully${NC}"

        # Show deployment summary
        echo -e "${BLUE}=== Deployment Summary ===${NC}"
        echo -e "${BLUE}Environment: ${GREEN}$ENVIRONMENT${NC}"
        if [[ "$ENVIRONMENT" == "testing" ]]; then
            echo -e "${GREEN}EKS Nodes: Public subnets with internet access${NC}"
            echo -e "${GREEN}NAT Gateways: None (saving $135/month)${NC}"
        else
            echo -e "${YELLOW}EKS Nodes: Private subnets${NC}"
            echo -e "${YELLOW}NAT Gateways: $(terraform output -raw nat_gateway_count)${NC}"
        fi
        ;;
    destroy)
        terraform destroy -var-file="$TFVARS_FILE" -auto-approve
        echo -e "${GREEN}✓ Resources destroyed successfully${NC}"
        ;;
esac

echo -e "${BLUE}=== Deployment Complete ===${NC}"