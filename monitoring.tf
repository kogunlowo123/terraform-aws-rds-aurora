################################################################################
# Enhanced Monitoring IAM Role
################################################################################

resource "aws_iam_role" "monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  name        = "${var.cluster_identifier}-monitoring-role"
  description = "IAM role for RDS Enhanced Monitoring for ${var.cluster_identifier}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# CloudWatch Alarms - CPU Utilization
################################################################################

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.engine_mode == "serverless" ? 0 : var.instance_count

  alarm_name          = "${var.cluster_identifier}-${count.index}-cpu-utilization"
  alarm_description   = "CPU utilization alarm for ${var.cluster_identifier}-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.this[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${count.index}-cpu-alarm"
  })
}

################################################################################
# CloudWatch Alarms - Database Connections
################################################################################

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count = var.engine_mode == "serverless" ? 0 : var.instance_count

  alarm_name          = "${var.cluster_identifier}-${count.index}-connections"
  alarm_description   = "Database connections alarm for ${var.cluster_identifier}-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.this[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${count.index}-connections-alarm"
  })
}

################################################################################
# CloudWatch Alarms - Replication Lag
################################################################################

resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  count = var.engine_mode == "serverless" ? 0 : (var.instance_count > 1 ? var.instance_count - 1 : 0)

  alarm_name          = "${var.cluster_identifier}-${count.index + 1}-replication-lag"
  alarm_description   = "Replication lag alarm for ${var.cluster_identifier}-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = var.engine == "aurora-mysql" ? "AuroraReplicaLag" : "ReplicationLag"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.this[count.index + 1].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${count.index + 1}-replication-lag-alarm"
  })
}
