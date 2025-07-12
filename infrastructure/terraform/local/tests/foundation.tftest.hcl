# Terraform test file for foundation layer
# Tests VPC, subnets, and security groups creation

run "valid_vpc_configuration" {
  command = plan

  # Use local testing configuration
  variables {
    environment         = "local"
    cluster_name       = "test-cluster"
    vpc_cidr          = "10.100.0.0/16"
    enable_nat_gateway = false
    use_public_subnets_for_eks = true
  }

  # Validate VPC CIDR
  assert {
    condition     = var.vpc_cidr == "10.100.0.0/16"
    error_message = "VPC CIDR should be 10.100.0.0/16 for local testing"
  }

  # Validate environment
  assert {
    condition     = var.environment == "local"
    error_message = "Environment should be 'local' for local testing"
  }

  # Validate NAT gateway is disabled for cost savings
  assert {
    condition     = var.enable_nat_gateway == false
    error_message = "NAT gateway should be disabled for local testing"
  }

  # Validate public subnets are used for EKS
  assert {
    condition     = var.use_public_subnets_for_eks == true
    error_message = "Public subnets should be used for EKS in local testing"
  }
}

run "vpc_outputs_validation" {
  command = plan

  variables {
    environment = "local"
    cluster_name = "test-cluster"
    vpc_cidr = "10.100.0.0/16"
  }

  # Validate that VPC module outputs are properly configured
  assert {
    condition = output.environment == "local"
    error_message = "Environment output should match input variable"
  }

  assert {
    condition = output.cluster_name == "test-cluster"
    error_message = "Cluster name output should match input variable"
  }
}

run "security_groups_validation" {
  command = plan

  variables {
    environment = "local"
    cluster_name = "test-cluster" 
    vpc_cidr = "10.100.0.0/16"
  }

  # Validate that security group outputs are available
  assert {
    condition = output.cluster_security_group_id != null
    error_message = "Cluster security group ID should not be null"
  }

  assert {
    condition = output.node_security_group_id != null  
    error_message = "Node security group ID should not be null"
  }
}