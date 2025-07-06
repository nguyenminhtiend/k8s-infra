# =============================================================================
# PHASE 3: AUTOSCALING & LOAD BALANCING OUTPUTS
# =============================================================================

# =============================================================================
# KARPENTER OUTPUTS
# =============================================================================

output "karpenter_enabled" {
  description = "Whether Karpenter is enabled"
  value       = var.karpenter_enabled
}

output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = var.karpenter_enabled ? aws_iam_role.karpenter_controller_role[0].arn : null
}

output "karpenter_node_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = var.karpenter_enabled ? aws_iam_role.karpenter_node_role[0].arn : null
}

output "karpenter_instance_profile_name" {
  description = "Name of the Karpenter node instance profile"
  value       = var.karpenter_enabled ? aws_iam_instance_profile.karpenter_node_instance_profile[0].name : null
}

output "karpenter_interruption_queue_name" {
  description = "Name of the Karpenter interruption SQS queue"
  value       = var.karpenter_enabled ? aws_sqs_queue.karpenter_interruption_queue[0].name : null
}

output "karpenter_version" {
  description = "Version of Karpenter deployed"
  value       = var.karpenter_enabled ? var.karpenter_version : null
}

output "karpenter_nodepool_config" {
  description = "Karpenter NodePool configuration summary"
  value = var.karpenter_enabled ? {
    instance_types    = var.karpenter_node_instance_types
    capacity_types    = var.karpenter_node_capacity_type
    spot_percentage   = var.karpenter_spot_percentage
    max_nodes         = var.karpenter_max_nodes
    ttl_after_empty   = var.karpenter_ttl_seconds_after_empty
    ttl_until_expired = var.karpenter_ttl_seconds_until_expired
  } : null
}

# =============================================================================
# AWS LOAD BALANCER CONTROLLER OUTPUTS
# =============================================================================

output "alb_controller_enabled" {
  description = "Whether AWS Load Balancer Controller is enabled"
  value       = var.alb_controller_enabled
}

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.alb_controller_enabled ? aws_iam_role.alb_controller_role[0].arn : null
}

output "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller deployed"
  value       = var.alb_controller_enabled ? var.alb_controller_version : null
}

output "alb_controller_service_account_name" {
  description = "Name of the AWS Load Balancer Controller service account"
  value       = var.alb_controller_enabled ? kubernetes_service_account.alb_controller[0].metadata[0].name : null
}

# =============================================================================
# EXTERNAL DNS OUTPUTS
# =============================================================================

output "external_dns_enabled" {
  description = "Whether External DNS is enabled"
  value       = var.external_dns_enabled
}

output "external_dns_role_arn" {
  description = "ARN of the External DNS IAM role"
  value       = var.external_dns_enabled ? aws_iam_role.external_dns_role[0].arn : null
}

output "external_dns_version" {
  description = "Version of External DNS deployed"
  value       = var.external_dns_enabled ? var.external_dns_version : null
}

output "external_dns_config" {
  description = "External DNS configuration summary"
  value = var.external_dns_enabled ? {
    domain_filters = var.external_dns_domain_filters
    sources        = var.external_dns_source
    txt_owner_id   = var.external_dns_txt_owner_id != "" ? var.external_dns_txt_owner_id : "external-dns-${var.environment}"
  } : null
}

# =============================================================================
# CLUSTER AUTOSCALER OUTPUTS
# =============================================================================

output "cluster_autoscaler_enabled" {
  description = "Whether Cluster Autoscaler is enabled"
  value       = var.cluster_autoscaler_enabled
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role"
  value       = var.cluster_autoscaler_enabled ? aws_iam_role.cluster_autoscaler_role[0].arn : null
}

output "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler deployed"
  value       = var.cluster_autoscaler_enabled ? var.cluster_autoscaler_version : null
}

output "cluster_autoscaler_config" {
  description = "Cluster Autoscaler configuration summary"
  value = var.cluster_autoscaler_enabled ? {
    scale_down_delay_after_add       = var.cluster_autoscaler_scale_down_delay_after_add
    scale_down_unneeded_time         = var.cluster_autoscaler_scale_down_unneeded_time
    scale_down_utilization_threshold = var.cluster_autoscaler_scale_down_utilization_threshold
  } : null
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "container_insights_enabled" {
  description = "Whether CloudWatch Container Insights is enabled"
  value       = var.enable_container_insights
}

output "container_insights_log_group" {
  description = "CloudWatch log group for Container Insights"
  value       = var.enable_container_insights ? aws_cloudwatch_log_group.container_insights[0].name : null
}

output "cost_monitoring_enabled" {
  description = "Whether cost monitoring is enabled"
  value       = var.enable_cost_monitoring
}

# =============================================================================
# CLUSTER CONFIGURATION OUTPUTS
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = data.terraform_remote_state.cluster.outputs.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = data.terraform_remote_state.cluster.outputs.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = data.terraform_remote_state.cluster.outputs.cluster_version
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.terraform_remote_state.foundation.outputs.vpc_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# =============================================================================
# OPERATIONAL OUTPUTS
# =============================================================================

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${data.terraform_remote_state.cluster.outputs.cluster_name}"
}

output "phase3_summary" {
  description = "Summary of Phase 3 deployment"
  value = {
    environment                = var.environment
    karpenter_enabled          = var.karpenter_enabled
    alb_controller_enabled     = var.alb_controller_enabled
    external_dns_enabled       = var.external_dns_enabled
    cluster_autoscaler_enabled = var.cluster_autoscaler_enabled
    container_insights_enabled = var.enable_container_insights
    cost_monitoring_enabled    = var.enable_cost_monitoring
    deployment_timestamp       = timestamp()
  }
}

# =============================================================================
# TESTING & VALIDATION OUTPUTS
# =============================================================================

output "validation_commands" {
  description = "Commands to validate Phase 3 deployment"
  value = {
    karpenter_pods          = var.karpenter_enabled ? "kubectl get pods -n karpenter" : "# Karpenter not enabled"
    karpenter_nodepools     = var.karpenter_enabled ? "kubectl get nodepools" : "# Karpenter not enabled"
    karpenter_nodeclaims    = var.karpenter_enabled ? "kubectl get nodeclaims" : "# Karpenter not enabled"
    alb_controller_pods     = var.alb_controller_enabled ? "kubectl get pods -n kube-system | grep aws-load-balancer-controller" : "# ALB Controller not enabled"
    external_dns_pods       = var.external_dns_enabled ? "kubectl get pods -n kube-system | grep external-dns" : "# External DNS not enabled"
    cluster_autoscaler_pods = var.cluster_autoscaler_enabled ? "kubectl get pods -n kube-system | grep cluster-autoscaler" : "# Cluster Autoscaler not enabled"
    node_status             = "kubectl get nodes -o wide"
    system_pods             = "kubectl get pods -n kube-system"
  }
}

output "cost_optimization_summary" {
  description = "Cost optimization features summary"
  value = {
    spot_instances_enabled = var.karpenter_enabled && contains(var.karpenter_node_capacity_type, "spot")
    spot_percentage        = var.karpenter_spot_percentage
    auto_scaling_enabled   = var.karpenter_enabled || var.cluster_autoscaler_enabled
    right_sizing_enabled   = var.karpenter_enabled
    scale_to_zero_enabled  = var.karpenter_enabled
    bin_packing_enabled    = var.karpenter_enabled
    estimated_monthly_cost = var.environment == "testing" ? "$110-151" : (var.environment == "staging" ? "$200-400" : "$500-1000")
  }
}

output "troubleshooting_guide" {
  description = "Troubleshooting commands and tips"
  value = {
    karpenter_logs          = var.karpenter_enabled ? "kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter" : "# Karpenter not enabled"
    alb_controller_logs     = var.alb_controller_enabled ? "kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller" : "# ALB Controller not enabled"
    external_dns_logs       = var.external_dns_enabled ? "kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns" : "# External DNS not enabled"
    cluster_autoscaler_logs = var.cluster_autoscaler_enabled ? "kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler" : "# Cluster Autoscaler not enabled"
    node_describe           = "kubectl describe nodes"
    events                  = "kubectl get events --sort-by=.metadata.creationTimestamp"
    resource_usage          = "kubectl top nodes && kubectl top pods -A"
  }
}

# =============================================================================
# NEXT STEPS OUTPUT
# =============================================================================

output "next_steps" {
  description = "Next steps after Phase 3 completion"
  value       = <<-EOT
    # Phase 3 Completion - Next Steps

    🎉 Phase 3 Complete! Your cluster now has intelligent autoscaling and load balancing.

    ## Validation Steps:
    1. Check component health:
       ${var.karpenter_enabled ? "kubectl get pods -n karpenter" : "# Karpenter not enabled"}
       ${var.alb_controller_enabled ? "kubectl get pods -n kube-system | grep aws-load-balancer-controller" : "# ALB Controller not enabled"}
       ${var.external_dns_enabled ? "kubectl get pods -n kube-system | grep external-dns" : "# External DNS not enabled"}

    2. Test node provisioning:
       kubectl apply -f https://raw.githubusercontent.com/aws/karpenter/main/examples/v1beta1/hello-world.yaml

    3. Monitor scaling:
       kubectl get nodes -w

    ## Ready for Phase 4:
    - ArgoCD for GitOps
    - Application deployments
    - Monitoring stack
    - Production workloads

    ## Cost Monitoring:
    - Estimated cost: ${var.environment == "testing" ? "$110-151/month" : (var.environment == "staging" ? "$200-400/month" : "$500-1000/month")}
    - ${var.karpenter_enabled && contains(var.karpenter_node_capacity_type, "spot") ? "Spot instances enabled (${var.karpenter_spot_percentage}%)" : "On-demand instances only"}
    - Auto-scaling: ${var.karpenter_enabled || var.cluster_autoscaler_enabled ? "✅ Enabled" : "❌ Disabled"}

    Environment: ${var.environment}
    Cluster: ${data.terraform_remote_state.cluster.outputs.cluster_name}
    Region: ${var.aws_region}
  EOT
}
