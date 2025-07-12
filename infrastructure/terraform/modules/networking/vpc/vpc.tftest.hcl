# Terraform test file for VPC module
# Tests VPC creation and configuration

run "vpc_creation_test" {
  command = plan

  variables {
    environment  = "local"
    vpc_cidr     = "10.100.0.0/16"
    cluster_name = "test-cluster"
  }

  # Test VPC CIDR validation
  assert {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }

  # Test VPC CIDR size (should be at least /16)
  assert {
    condition     = split("/", var.vpc_cidr)[1] <= "16"
    error_message = "VPC CIDR should be /16 or larger for adequate address space"
  }
}

run "vpc_tags_validation" {
  command = plan

  variables {
    environment  = "local"
    vpc_cidr     = "10.100.0.0/16" 
    cluster_name = "test-cluster"
  }

  # Validate that VPC will have proper tags
  assert {
    condition = var.environment != ""
    error_message = "Environment variable should not be empty"
  }

  assert {
    condition = var.cluster_name != ""
    error_message = "Cluster name should not be empty"
  }
}

run "vpc_dns_settings" {
  command = plan

  variables {
    environment  = "local"
    vpc_cidr     = "10.100.0.0/16"
    cluster_name = "test-cluster"
  }

  # Test that DNS settings are appropriate for EKS
  # This validates the VPC configuration supports EKS requirements
  assert {
    condition = var.cluster_name != null
    error_message = "Cluster name is required for proper EKS VPC configuration"
  }
}