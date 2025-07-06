# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Launch template for EKS node groups
resource "aws_launch_template" "eks_node_group_template" {
  name_prefix   = "eks-node-group-${var.cluster_name}-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_types[0]

  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name        = var.cluster_name
    bootstrap_arguments = var.bootstrap_arguments
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name        = "EKS-Node-${var.cluster_name}-${var.environment}"
      Environment = var.environment
      Module      = "eks/node-groups"
      ManagedBy   = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name        = "EKS-Node-Volume-${var.cluster_name}-${var.environment}"
      Environment = var.environment
      Module      = "eks/node-groups"
      ManagedBy   = "terraform"
    })
  }

  tags = merge(var.tags, {
    Name        = "EKS-NodeGroup-LaunchTemplate-${var.cluster_name}-${var.environment}"
    Environment = var.environment
    Module      = "eks/node-groups"
    ManagedBy   = "terraform"
  })
}

# EKS Node Group
resource "aws_eks_node_group" "system_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "system-nodes-${var.environment}"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.subnet_ids

  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  launch_template {
    id      = aws_launch_template.eks_node_group_template.id
    version = aws_launch_template.eks_node_group_template.latest_version
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling
  depends_on = [
    aws_launch_template.eks_node_group_template,
  ]

  # Apply taints for system workloads
  dynamic "taint" {
    for_each = var.enable_system_taints ? [1] : []
    content {
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  # Allow system pods to be scheduled on these nodes
  labels = merge(var.labels, {
    "node-type" = "system"
    "capacity-type" = var.capacity_type
  })

  tags = merge(var.tags, {
    Name        = "EKS-NodeGroup-${var.cluster_name}-${var.environment}"
    Environment = var.environment
    Module      = "eks/node-groups"
    ManagedBy   = "terraform"
  })
}

# Auto Scaling Group tags for cluster autoscaler
resource "aws_autoscaling_group_tag" "cluster_autoscaler_enabled" {
  autoscaling_group_name = aws_eks_node_group.system_node_group.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_cluster_name" {
  autoscaling_group_name = aws_eks_node_group.system_node_group.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}