################################################################################
# Global Cluster
################################################################################

resource "aws_rds_global_cluster" "this" {
  count = var.enable_global_cluster ? 1 : 0

  global_cluster_identifier = var.global_cluster_identifier
  engine                    = var.engine
  engine_version            = var.engine_version
  storage_encrypted         = var.storage_encrypted
  database_name             = var.database_name
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name        = "${var.cluster_identifier}-subnet-group"
  description = "Subnet group for Aurora cluster ${var.cluster_identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-subnet-group"
  })
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.cluster_identifier}-cluster-params"
  family      = coalesce(var.cluster_parameter_group_family, var.engine == "aurora-mysql" ? "aurora-mysql8.0" : "aurora-postgresql15")
  description = "Cluster parameter group for ${var.cluster_identifier}"

  dynamic "parameter" {
    for_each = var.cluster_parameter_group_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-cluster-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Instance Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  name        = "${var.cluster_identifier}-instance-params"
  family      = coalesce(var.cluster_parameter_group_family, var.engine == "aurora-mysql" ? "aurora-mysql8.0" : "aurora-postgresql15")
  description = "Instance parameter group for ${var.cluster_identifier}"

  dynamic "parameter" {
    for_each = var.instance_parameter_group_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-instance-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Aurora Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
  engine             = var.engine
  engine_version     = var.engine_version
  engine_mode        = var.engine_mode

  global_cluster_identifier = var.enable_global_cluster ? aws_rds_global_cluster.this[0].id : null

  database_name   = var.database_name
  master_username = var.master_username
  port            = coalesce(var.port, var.engine == "aurora-mysql" ? 3306 : 5432)

  manage_master_user_password = var.manage_master_user_password ? true : null
  master_password             = var.manage_master_user_password ? null : var.master_password

  db_subnet_group_name            = aws_db_subnet_group.this.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_arn

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  deletion_protection       = var.enable_deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  copy_tags_to_snapshot = true

  dynamic "scaling_configuration" {
    for_each = var.engine_mode == "serverless" && var.scaling_configuration != null ? [var.scaling_configuration] : []
    content {
      min_capacity             = scaling_configuration.value.min_capacity
      max_capacity             = scaling_configuration.value.max_capacity
      auto_pause               = scaling_configuration.value.auto_pause
      seconds_until_auto_pause = 300
    }
  }

  tags = merge(var.tags, {
    Name = var.cluster_identifier
  })

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      global_cluster_identifier,
    ]
  }

  depends_on = [
    aws_rds_global_cluster.this,
  ]
}

################################################################################
# Cluster Instances
################################################################################

resource "aws_rds_cluster_instance" "this" {
  count = var.engine_mode == "serverless" ? 0 : var.instance_count

  identifier         = "${var.cluster_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = var.engine
  engine_version     = var.engine_version
  instance_class     = var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name

  publicly_accessible = false

  monitoring_interval = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? aws_iam_role.monitoring[0].arn : null

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.enable_performance_insights && var.kms_key_arn != null ? var.kms_key_arn : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  promotion_tier             = count.index

  copy_tags_to_snapshot = true

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${count.index}"
  })
}

################################################################################
# Activity Stream
################################################################################

resource "aws_rds_cluster_activity_stream" "this" {
  count = var.enable_activity_stream ? 1 : 0

  resource_arn = aws_rds_cluster.this.arn
  mode         = var.activity_stream_mode
  kms_key_id   = var.kms_key_arn

  depends_on = [aws_rds_cluster_instance.this]
}

################################################################################
# Auto Scaling
################################################################################

resource "aws_appautoscaling_target" "read_replicas" {
  count = var.autoscaling_enabled ? 1 : 0

  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:${aws_rds_cluster.this.id}"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity

  depends_on = [aws_rds_cluster_instance.this]
}

resource "aws_appautoscaling_policy" "read_replicas" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "${var.cluster_identifier}-read-replica-scaling"
  service_namespace  = aws_appautoscaling_target.read_replicas[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.read_replicas[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.read_replicas[0].resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    target_value       = var.autoscaling_target_cpu
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
