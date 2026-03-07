################################################################################
# Cluster
################################################################################

output "cluster_id" {
  description = "The Aurora cluster identifier."
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster."
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The cluster writer endpoint."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "The cluster reader endpoint for read-only connections."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "The port the Aurora cluster is listening on."
  value       = aws_rds_cluster.this.port
}

################################################################################
# Instances
################################################################################

output "instance_ids" {
  description = "List of Aurora cluster instance identifiers."
  value       = aws_rds_cluster_instance.this[*].id
}

output "instance_arns" {
  description = "List of Aurora cluster instance ARNs."
  value       = aws_rds_cluster_instance.this[*].arn
}

output "instance_endpoints" {
  description = "List of Aurora cluster instance endpoints."
  value       = aws_rds_cluster_instance.this[*].endpoint
}

################################################################################
# RDS Proxy
################################################################################

output "proxy_endpoint" {
  description = "The endpoint of the RDS Proxy."
  value       = var.enable_rds_proxy ? aws_db_proxy.this[0].endpoint : null
}

output "proxy_arn" {
  description = "The ARN of the RDS Proxy."
  value       = var.enable_rds_proxy ? aws_db_proxy.this[0].arn : null
}

output "proxy_read_only_endpoint" {
  description = "The read-only endpoint of the RDS Proxy."
  value       = var.enable_rds_proxy ? aws_db_proxy_endpoint.read_only[0].endpoint : null
}

################################################################################
# Global Cluster
################################################################################

output "global_cluster_id" {
  description = "The identifier of the global Aurora cluster."
  value       = var.enable_global_cluster ? aws_rds_global_cluster.this[0].id : null
}

output "global_cluster_arn" {
  description = "The ARN of the global Aurora cluster."
  value       = var.enable_global_cluster ? aws_rds_global_cluster.this[0].arn : null
}

################################################################################
# Security
################################################################################

output "security_group_id" {
  description = "The ID of the security group created for the Aurora cluster."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the security group created for the Aurora cluster."
  value       = aws_security_group.this.arn
}

################################################################################
# Monitoring
################################################################################

output "enhanced_monitoring_role_arn" {
  description = "The ARN of the enhanced monitoring IAM role."
  value       = var.enable_enhanced_monitoring ? aws_iam_role.monitoring[0].arn : null
}

################################################################################
# Activity Stream
################################################################################

output "activity_stream_kinesis_stream_name" {
  description = "The name of the Kinesis stream for database activity."
  value       = var.enable_activity_stream ? aws_rds_cluster_activity_stream.this[0].kinesis_stream_name : null
}

################################################################################
# Subnet Group
################################################################################

output "db_subnet_group_name" {
  description = "The name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

################################################################################
# Parameter Groups
################################################################################

output "cluster_parameter_group_name" {
  description = "The name of the cluster parameter group."
  value       = aws_rds_cluster_parameter_group.this.name
}

output "instance_parameter_group_name" {
  description = "The name of the instance parameter group."
  value       = aws_db_parameter_group.this.name
}
