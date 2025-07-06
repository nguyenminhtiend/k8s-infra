# EKS Infrastructure Implementation - Step-by-Step Plan

## Overview

This plan breaks down the EKS infrastructure into **small, manageable steps** that can be implemented and validated incrementally. Each step builds on the previous one and includes validation commands.

## Prerequisites Checklist

### Step 0: Setup & Prerequisites

- [ ] **0.1** Install required tools

  ```bash
  # Install AWS CLI v2 (macOS)
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /

  # Install AWS CLI v2 (Linux)
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip && sudo ./aws/install

  # Install Terraform (latest version)
  brew install terraform  # or download from terraform.io

  # Install kubectl
  brew install kubectl

  # Install eksctl
  brew install eksctl

  # Verify installations
  aws --version
  terraform --version
  kubectl version --client
  eksctl version
  ```

- [ ] **0.2** Configure AWS credentials

  ```bash
  aws configure
  # AWS Access Key ID: [your-access-key]
  # AWS Secret Access Key: [your-secret-key]
  # Default region name: ap-southeast-1
  # Default output format: json

  # Test connection
  aws sts get-caller-identity
  ```

- [ ] **0.3** Create S3 bucket for Terraform state

  ```bash
  # Create unique bucket name
  BUCKET_NAME="terraform-state-eks-$(date +%s)"
  aws s3 mb s3://$BUCKET_NAME --region ap-southeast-1

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }'

  # Save bucket name for later
  echo $BUCKET_NAME > terraform-state-bucket.txt
  ```

- [ ] **0.4** Create DynamoDB table for state locking

  ```bash
  aws dynamodb create-table \
    --table-name terraform-state-lock-eks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-southeast-1

  # Wait for table to be active
  aws dynamodb wait table-exists --table-name terraform-state-lock-eks
  ```

- [ ] **0.5** Create project structure

  ```bash
  mkdir -p infrastructure/terraform/{modules,layers}
  mkdir -p infrastructure/terraform/modules/{networking,iam,eks,irsa,karpenter,applications}
  mkdir -p infrastructure/terraform/layers/{01-foundation,02-cluster,03-autoscaling,04-applications}

  # Verify structure
  tree infrastructure/terraform/
  ```

## Phase 1: Foundation Infrastructure (Week 1)

### Step 1: VPC Module

- [ ] **1.1** Create VPC module structure

  ```bash
  mkdir -p infrastructure/terraform/modules/networking/vpc
  touch infrastructure/terraform/modules/networking/vpc/{main.tf,variables.tf,outputs.tf}
  ```

- [ ] **1.2** Implement VPC module

  ```hcl
  # infrastructure/terraform/modules/networking/vpc/variables.tf
  variable "environment" {
    description = "Environment name"
    type        = string
  }

  variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type        = string
    default     = "10.0.0.0/16"
  }

  variable "cluster_name" {
    description = "EKS cluster name"
    type        = string
  }
  ```

- [ ] **1.3** Create VPC resources

  ```hcl
  # infrastructure/terraform/modules/networking/vpc/main.tf
  resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
      Name                                        = "vpc-${var.environment}"
      Environment                                 = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  }

  resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name        = "igw-${var.environment}"
      Environment = var.environment
    }
  }
  ```

- [ ] **1.4** Add VPC outputs

  ```hcl
  # infrastructure/terraform/modules/networking/vpc/outputs.tf
  output "vpc_id" {
    description = "ID of the VPC"
    value       = aws_vpc.main.id
  }

  output "vpc_cidr_block" {
    description = "CIDR block of the VPC"
    value       = aws_vpc.main.cidr_block
  }

  output "internet_gateway_id" {
    description = "ID of the Internet Gateway"
    value       = aws_internet_gateway.main.id
  }
  ```

- [ ] **1.5** Test VPC module

  ```bash
  cd infrastructure/terraform/modules/networking/vpc
  terraform init
  terraform plan -var="environment=test" -var="cluster_name=test-cluster"
  terraform apply -var="environment=test" -var="cluster_name=test-cluster"

  # Verify VPC creation
  aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-test"

  # Clean up test
  terraform destroy -var="environment=test" -var="cluster_name=test-cluster"
  ```

### Step 2: Subnets Module

- [ ] **2.1** Create subnets module structure

  ```bash
  mkdir -p infrastructure/terraform/modules/networking/subnets
  touch infrastructure/terraform/modules/networking/subnets/{main.tf,variables.tf,outputs.tf}
  ```

- [ ] **2.2** Implement subnets module

  ```hcl
  # infrastructure/terraform/modules/networking/subnets/variables.tf
  variable "environment" {
    description = "Environment name"
    type        = string
  }

  variable "vpc_id" {
    description = "VPC ID"
    type        = string
  }

  variable "vpc_cidr" {
    description = "VPC CIDR block"
    type        = string
  }

  variable "cluster_name" {
    description = "EKS cluster name"
    type        = string
  }

  variable "availability_zones" {
    description = "Availability zones"
    type        = list(string)
    default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  }
  ```

- [ ] **2.3** Create public subnets

  ```hcl
  # infrastructure/terraform/modules/networking/subnets/main.tf
  resource "aws_subnet" "public" {
    count = length(var.availability_zones)

    vpc_id                  = var.vpc_id
    cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
    availability_zone       = var.availability_zones[count.index]
    map_public_ip_on_launch = true

    tags = {
      Name                                        = "public-subnet-${var.environment}-${count.index + 1}"
      Environment                                 = var.environment
      Type                                        = "public"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    }
  }

  resource "aws_subnet" "private" {
    count = length(var.availability_zones)

    vpc_id            = var.vpc_id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
    availability_zone = var.availability_zones[count.index]

    tags = {
      Name                                        = "private-subnet-${var.environment}-${count.index + 1}"
      Environment                                 = var.environment
      Type                                        = "private"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    }
  }
  ```

- [ ] **2.4** Create NAT gateways

  ```hcl
  # Add to subnets/main.tf
  resource "aws_eip" "nat" {
    count = length(var.availability_zones)

    domain = "vpc"

    tags = {
      Name        = "nat-eip-${var.environment}-${count.index + 1}"
      Environment = var.environment
    }
  }

  resource "aws_nat_gateway" "main" {
    count = length(var.availability_zones)

    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id

    tags = {
      Name        = "nat-gw-${var.environment}-${count.index + 1}"
      Environment = var.environment
    }
  }
  ```

- [ ] **2.5** Add subnet outputs

  ```hcl
  # infrastructure/terraform/modules/networking/subnets/outputs.tf
  output "public_subnet_ids" {
    description = "IDs of public subnets"
    value       = aws_subnet.public[*].id
  }

  output "private_subnet_ids" {
    description = "IDs of private subnets"
    value       = aws_subnet.private[*].id
  }

  output "nat_gateway_ids" {
    description = "IDs of NAT gateways"
    value       = aws_nat_gateway.main[*].id
  }
  ```

- [ ] **2.6** Test subnets module

  ```bash
  cd infrastructure/terraform/modules/networking/subnets
  terraform init

  # Create test VPC first
  VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

  # Test subnets
  terraform plan -var="environment=test" -var="vpc_id=$VPC_ID" -var="vpc_cidr=10.0.0.0/16" -var="cluster_name=test-cluster"
  terraform apply -var="environment=test" -var="vpc_id=$VPC_ID" -var="vpc_cidr=10.0.0.0/16" -var="cluster_name=test-cluster"

  # Verify subnets
  aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

  # Clean up
  terraform destroy -var="environment=test" -var="vpc_id=$VPC_ID" -var="vpc_cidr=10.0.0.0/16" -var="cluster_name=test-cluster"
  aws ec2 delete-vpc --vpc-id $VPC_ID
  ```

### Step 3: Security Groups Module

- [ ] **3.1** Create security groups module

  ```bash
  mkdir -p infrastructure/terraform/modules/networking/security-groups
  touch infrastructure/terraform/modules/networking/security-groups/{main.tf,variables.tf,outputs.tf}
  ```

- [ ] **3.2** Implement security groups (updated for 2024)

  ```hcl
  # infrastructure/terraform/modules/networking/security-groups/main.tf
  resource "aws_security_group" "eks_cluster" {
    name_prefix = "eks-cluster-${var.environment}"
    vpc_id      = var.vpc_id

    ingress {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }

    # Allow EFA traffic (for AI/ML workloads)
    ingress {
      from_port = 0
      to_port   = 65535
      protocol  = "tcp"
      self      = true
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "eks-cluster-sg-${var.environment}"
      Environment = var.environment
    }
  }

  resource "aws_security_group" "eks_nodes" {
    name_prefix = "eks-nodes-${var.environment}"
    vpc_id      = var.vpc_id

    ingress {
      from_port = 0
      to_port   = 65535
      protocol  = "tcp"
      self      = true
    }

    ingress {
      from_port       = 1025
      to_port         = 65535
      protocol        = "tcp"
      security_groups = [aws_security_group.eks_cluster.id]
    }

    # Allow EFA traffic for AI/ML workloads
    ingress {
      from_port = 0
      to_port   = 65535
      protocol  = "tcp"
      self      = true
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name        = "eks-nodes-sg-${var.environment}"
      Environment = var.environment
    }
  }
  ```

- [ ] **3.3** Test security groups module

  ```bash
  cd infrastructure/terraform/modules/networking/security-groups
  terraform init

  # Test with existing VPC
  terraform plan -var="environment=test" -var="vpc_id=$VPC_ID" -var="vpc_cidr=10.0.0.0/16"
  ```

### Step 4: Layer 1 - Foundation Layer

- [ ] **4.1** Create Layer 1 structure

  ```bash
  mkdir -p infrastructure/terraform/layers/01-foundation
  touch infrastructure/terraform/layers/01-foundation/{main.tf,variables.tf,outputs.tf,terraform.tf}
  ```

- [ ] **4.2** Configure Terraform backend (updated syntax)

  ```hcl
  # infrastructure/terraform/layers/01-foundation/terraform.tf
  terraform {
    required_version = ">= 1.0"

    backend "s3" {
      bucket         = "YOUR_BUCKET_NAME"  # Replace with your bucket
      key            = "eks/01-foundation/terraform.tfstate"
      region         = "ap-southeast-1"
      dynamodb_table = "terraform-state-lock-eks"
      encrypt        = true
    }

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }

  provider "aws" {
    region = var.aws_region
  }
  ```

- [ ] **4.3** Create Layer 1 variables

  ```hcl
  # infrastructure/terraform/layers/01-foundation/variables.tf
  variable "environment" {
    description = "Environment name"
    type        = string
    default     = "dev"
  }

  variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "ap-southeast-1"
  }

  variable "cluster_name" {
    description = "EKS cluster name"
    type        = string
    default     = "my-cluster"
  }

  variable "vpc_cidr" {
    description = "VPC CIDR block"
    type        = string
    default     = "10.0.0.0/16"
  }
  ```

- [ ] **4.4** Implement Layer 1 main

  ```hcl
  # infrastructure/terraform/layers/01-foundation/main.tf
  data "aws_caller_identity" "current" {}

  module "vpc" {
    source = "../../modules/networking/vpc"

    environment  = var.environment
    vpc_cidr     = var.vpc_cidr
    cluster_name = var.cluster_name
  }

  module "subnets" {
    source = "../../modules/networking/subnets"

    environment  = var.environment
    vpc_id       = module.vpc.vpc_id
    vpc_cidr     = module.vpc.vpc_cidr_block
    cluster_name = var.cluster_name
  }

  module "security_groups" {
    source = "../../modules/networking/security-groups"

    environment = var.environment
    vpc_id      = module.vpc.vpc_id
    vpc_cidr    = module.vpc.vpc_cidr_block
  }
  ```

- [ ] **4.5** Add Layer 1 outputs

  ```hcl
  # infrastructure/terraform/layers/01-foundation/outputs.tf
  output "vpc_id" {
    description = "VPC ID"
    value       = module.vpc.vpc_id
  }

  output "private_subnet_ids" {
    description = "Private subnet IDs"
    value       = module.subnets.private_subnet_ids
  }

  output "public_subnet_ids" {
    description = "Public subnet IDs"
    value       = module.subnets.public_subnet_ids
  }

  output "cluster_security_group_id" {
    description = "EKS cluster security group ID"
    value       = module.security_groups.cluster_security_group_id
  }

  output "nodes_security_group_id" {
    description = "EKS nodes security group ID"
    value       = module.security_groups.nodes_security_group_id
  }
  ```

- [ ] **4.6** Deploy Layer 1

  ```bash
  cd infrastructure/terraform/layers/01-foundation

  # Update bucket name in terraform.tf
  BUCKET_NAME=$(cat ../../../../terraform-state-bucket.txt)
  sed -i "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" terraform.tf

  # Initialize and deploy
  terraform init
  terraform plan
  terraform apply

  # Verify deployment
  terraform output
  ```

- [ ] **4.7** Validate Layer 1

  ```bash
  # Check VPC
  aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-dev"

  # Check subnets
  aws ec2 describe-subnets --filters "Name=tag:Environment,Values=dev"

  # Check security groups
  aws ec2 describe-security-groups --filters "Name=tag:Environment,Values=dev"

  # Check NAT gateways
  aws ec2 describe-nat-gateways --filter "Name=tag:Environment,Values=dev"
  ```

## Phase 2: EKS Cluster (Week 2)

### Step 5: IAM Developer Roles Module

- [ ] **5.1** Create IAM developer roles module

  ```bash
  mkdir -p infrastructure/terraform/modules/iam/developer-roles
  touch infrastructure/terraform/modules/iam/developer-roles/{main.tf,variables.tf,outputs.tf}
  ```

- [ ] **5.2** Implement developer roles

  ```hcl
  # infrastructure/terraform/modules/iam/developer-roles/main.tf
  data "aws_caller_identity" "current" {}

  resource "aws_iam_role" "developer_base" {
    name = "EKS-Developer-Base-${var.environment}"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Condition = {
            StringEquals = {
              "sts:ExternalId" = var.external_id
            }
          }
        }
      ]
    })

    tags = {
      Environment = var.environment
      Module      = "iam/developer-roles"
    }
  }

  resource "aws_iam_policy" "developer_eks_access" {
    name        = "EKS-Developer-Access-${var.environment}"
    description = "Base EKS access for developers"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:DescribeNodegroup",
            "eks:ListNodegroups",
            "ec2:DescribeAvailabilityZones"
          ]
          Resource = [
            "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}*"
          ]
        }
      ]
    })
  }

  resource "aws_iam_role_policy_attachment" "developer_eks_access" {
    role       = aws_iam_role.developer_base.name
    policy_arn = aws_iam_policy.developer_eks_access.arn
  }
  ```

- [ ] **5.3** Test IAM module
  ```bash
  cd infrastructure/terraform/modules/iam/developer-roles
  terraform init
  terraform plan -var="environment=test" -var="cluster_name=test-cluster" -var="external_id=test-123" -var="aws_region=ap-southeast-1"
  ```

### Step 6: EKS Cluster Module

- [ ] **6.1** Create EKS cluster module

  ```bash
  mkdir -p infrastructure/terraform/modules/eks/cluster
  touch infrastructure/terraform/modules/eks/cluster/{main.tf,variables.tf,outputs.tf}
  ```

- [ ] **6.2** Implement EKS cluster (updated for 2024)

  ```hcl
  # infrastructure/terraform/modules/eks/cluster/main.tf
  resource "aws_iam_role" "eks_cluster" {
    name = "eks-cluster-role-${var.environment}"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
    })
  }

  resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster.name
  }

  resource "aws_eks_cluster" "main" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster.arn
    version  = var.kubernetes_version

    vpc_config {
      subnet_ids              = var.subnet_ids
      endpoint_private_access = true
      endpoint_public_access  = true
      public_access_cidrs     = ["0.0.0.0/0"]
      security_group_ids      = [var.cluster_security_group_id]
    }

    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    depends_on = [
      aws_iam_role_policy_attachment.eks_cluster_policy,
    ]

    tags = {
      Environment = var.environment
      Module      = "eks/cluster"
    }
  }
  ```

- [ ] **6.3** Add cluster variables (updated Kubernetes versions)

  ```hcl
  # infrastructure/terraform/modules/eks/cluster/variables.tf
  variable "cluster_name" {
    description = "EKS cluster name"
    type        = string
  }

  variable "kubernetes_version" {
    description = "Kubernetes version"
    type        = string
    default     = "1.33"  # Latest stable version
  }

  variable "subnet_ids" {
    description = "Subnet IDs for EKS cluster"
    type        = list(string)
  }

  variable "cluster_security_group_id" {
    description = "Security group ID for EKS cluster"
    type        = string
  }

  variable "environment" {
    description = "Environment name"
    type        = string
  }
  ```

### Step 7: Continue with remaining steps...

Would you like me to continue with the detailed steps for:

- [ ] **Phase 2**: EKS Node Groups, OIDC Provider
- [ ] **Phase 3**: Karpenter, Load Balancer Controller
- [ ] **Phase 4**: ArgoCD, Applications

Each step will include:

- Detailed implementation code
- Testing/validation commands
- Rollback procedures
- Dependency checks

Should I continue with the next phases, or would you like to start implementing Phase 1 first?
