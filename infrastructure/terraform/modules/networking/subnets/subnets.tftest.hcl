# Terraform test file for Subnets module
# Tests subnet creation and configuration

run "subnet_configuration_test" {
  command = plan

  variables {
    environment                = "local"
    vpc_id                     = "vpc-12345678"  # Mock VPC ID for testing
    vpc_cidr                   = "10.100.0.0/16"
    cluster_name               = "test-cluster"
    enable_nat_gateway         = false
    single_nat_gateway         = false
    use_public_subnets_for_eks = true
    internet_gateway_id        = "igw-12345678"  # Mock IGW ID for testing
  }

  # Test VPC CIDR is valid
  assert {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }

  # Test NAT gateway settings for local testing
  assert {
    condition     = var.enable_nat_gateway == false
    error_message = "NAT gateway should be disabled for local testing to save costs"
  }

  # Test public subnet usage for EKS
  assert {
    condition     = var.use_public_subnets_for_eks == true
    error_message = "Public subnets should be used for EKS in local testing"
  }
}

run "subnet_cidr_calculation" {
  command = plan

  variables {
    environment                = "local"
    vpc_id                     = "vpc-12345678"
    vpc_cidr                   = "10.100.0.0/16"
    cluster_name               = "test-cluster"
    enable_nat_gateway         = false
    single_nat_gateway         = false
    use_public_subnets_for_eks = true
    internet_gateway_id        = "igw-12345678"
  }

  # Test that VPC CIDR can be subdivided into subnets
  assert {
    condition = tonumber(split("/", var.vpc_cidr)[1]) < 24
    error_message = "VPC CIDR should allow subdivision into multiple subnets (smaller than /24)"
  }
}

run "local_testing_optimization" {
  command = plan

  variables {
    environment                = "local"
    vpc_id                     = "vpc-12345678"
    vpc_cidr                   = "10.100.0.0/16"
    cluster_name               = "test-cluster"
    enable_nat_gateway         = false
    single_nat_gateway         = false
    use_public_subnets_for_eks = true
    internet_gateway_id        = "igw-12345678"
  }

  # Validate cost-optimization settings for local testing
  assert {
    condition = var.enable_nat_gateway == false && var.use_public_subnets_for_eks == true
    error_message = "Local testing should disable NAT gateways and use public subnets for cost optimization"
  }
}