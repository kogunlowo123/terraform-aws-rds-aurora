variable "cluster_identifier" {
  description = "The identifier for the Aurora cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.cluster_identifier))
    error_message = "Cluster identifier must start with a letter, contain only lowercase alphanumeric characters and hyphens, and be at most 63 characters."
  }
}

variable "engine" {
  description = "The Aurora database engine type (aurora-mysql or aurora-postgresql)."
  type        = string

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "Engine must be either 'aurora-mysql' or 'aurora-postgresql'."
  }
}

variable "engine_version" {
  description = "The engine version to use for the Aurora cluster."
  type        = string
}

variable "engine_mode" {
  description = "The database engine mode (provisioned or serverless)."
  type        = string
  default     = "provisioned"

  validation {
    condition     = contains(["provisioned", "serverless"], var.engine_mode)
    error_message = "Engine mode must be either 'provisioned' or 'serverless'."
  }
}

variable "master_username" {
  description = "Username for the master database user."
  type        = string

  validation {
    condition     = length(var.master_username) >= 1 && length(var.master_username) <= 63
    error_message = "Master username must be between 1 and 63 characters."
  }
}

variable "manage_master_user_password" {
  description = "Whether to manage the master user password with Secrets Manager."
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Password for the master database user; required if manage_master_user_password is false."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.master_password == null || length(coalesce(var.master_password, " ")) >= 8
    error_message = "Master password must be at least 8 characters when provided."
  }
}

variable "database_name" {
  description = "Name for the automatically created database on cluster creation."
  type        = string
  default     = null
}

variable "port" {
  description = "The port on which the database accepts connections (1024-65535)."
  type        = number
  default     = null

  validation {
    condition     = var.port == null || (var.port >= 1024 && var.port <= 65535)
    error_message = "Port must be between 1024 and 65535."
  }
}

variable "vpc_id" {
  description = "The ID of the VPC where the Aurora cluster will be deployed."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid vpc-* identifier."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Aurora DB subnet group (minimum 2)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs are required for high availability."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to the Aurora cluster."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the Aurora cluster."
  type        = list(string)
  default     = []
}

variable "instance_count" {
  description = "Number of Aurora cluster instances to create (1-15)."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 15
    error_message = "Instance count must be between 1 and 15."
  }
}

variable "instance_class" {
  description = "The instance class for Aurora cluster instances."
  type        = string
  default     = "db.r6g.large"
}

variable "storage_encrypted" {
  description = "Whether the Aurora cluster storage is encrypted."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption; uses default AWS managed key if not specified."
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Number of days to retain backups (1-35)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "preferred_backup_window" {
  description = "Daily time range during which automated backups are created (UTC)."
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur (UTC)."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled on the Aurora cluster."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final DB snapshot when the cluster is deleted."
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Whether IAM database authentication is enabled."
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Whether Performance Insights is enabled for cluster instances."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Number of days to retain Performance Insights data."
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 31, 62, 93, 124, 155, 186, 217, 248, 279, 310, 341, 372, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be 7 (free tier) or a valid paid tier value (31-731)."
  }
}

variable "enable_enhanced_monitoring" {
  description = "Whether enhanced monitoring is enabled for cluster instances."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Interval in seconds between Enhanced Monitoring metrics collection."
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor engine upgrades are applied automatically during maintenance."
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (MySQL: audit, error, general, slowquery; PostgreSQL: postgresql)."
  type        = list(string)
  default     = []
}

variable "enable_global_cluster" {
  description = "Whether to create a global Aurora cluster for cross-region replication."
  type        = bool
  default     = false
}

variable "global_cluster_identifier" {
  description = "The global cluster identifier for the Aurora global database."
  type        = string
  default     = null
}

variable "enable_rds_proxy" {
  description = "Whether to create an RDS Proxy for the Aurora cluster."
  type        = bool
  default     = false
}

variable "proxy_idle_client_timeout" {
  description = "Seconds a proxy connection can be inactive before disconnect (60-28800)."
  type        = number
  default     = 1800

  validation {
    condition     = var.proxy_idle_client_timeout >= 60 && var.proxy_idle_client_timeout <= 28800
    error_message = "Proxy idle client timeout must be between 60 and 28800 seconds."
  }
}

variable "proxy_require_tls" {
  description = "Whether TLS/SSL is required for connections to the proxy."
  type        = bool
  default     = true
}

variable "enable_activity_stream" {
  description = "Whether to enable database activity streams on the Aurora cluster."
  type        = bool
  default     = false
}

variable "activity_stream_mode" {
  description = "The mode of the database activity stream (sync or async)."
  type        = string
  default     = "async"

  validation {
    condition     = contains(["sync", "async"], var.activity_stream_mode)
    error_message = "Activity stream mode must be either 'sync' or 'async'."
  }
}

variable "scaling_configuration" {
  description = "Scaling configuration for Aurora Serverless."
  type = object({
    min_capacity = optional(number, 0.5)
    max_capacity = optional(number, 16)
    auto_pause   = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.scaling_configuration == null || (var.scaling_configuration.min_capacity <= var.scaling_configuration.max_capacity)
    error_message = "min_capacity must be less than or equal to max_capacity."
  }
}

variable "autoscaling_enabled" {
  description = "Whether to enable auto-scaling for Aurora read replicas."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of read replicas when auto-scaling is enabled."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of read replicas when auto-scaling is enabled."
  type        = number
  default     = 5
}

variable "autoscaling_target_cpu" {
  description = "Target CPU utilization percentage for auto-scaling policy."
  type        = number
  default     = 70
}

variable "cluster_parameter_group_family" {
  description = "The family of the cluster parameter group (e.g., aurora-mysql8.0, aurora-postgresql15)."
  type        = string
  default     = null
}

variable "cluster_parameter_group_parameters" {
  description = "List of parameters to apply to the cluster parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "instance_parameter_group_parameters" {
  description = "List of parameters to apply to the instance parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
