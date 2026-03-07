################################################################################
# Complete Enterprise Aurora with Global Database, Monitoring, Activity Stream
################################################################################

provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "secondary"
}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "aurora" {
  provider = aws.primary

  description             = "KMS key for Aurora cluster encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "aurora-complete-kms"
  }
}

resource "aws_kms_alias" "aurora" {
  provider = aws.primary

  name          = "alias/aurora-complete"
  target_key_id = aws_kms_key.aurora.key_id
}

################################################################################
# Primary VPC
################################################################################

module "vpc_primary" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.primary
  }

  name = "aurora-complete-primary"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  tags = {
    Environment = "production"
  }
}

################################################################################
# Application Security Group
################################################################################

resource "aws_security_group" "app" {
  provider = aws.primary

  name   = "app-sg"
  vpc_id = module.vpc_primary.vpc_id

  tags = {
    Name = "app-sg"
  }
}

################################################################################
# Primary Aurora Cluster (Full Enterprise)
################################################################################

module "aurora_primary" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  cluster_identifier = "aurora-complete-primary"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"

  cluster_parameter_group_family = "aurora-postgresql15"

  master_username             = "dbadmin"
  manage_master_user_password = true

  database_name = "enterprise_app"

  vpc_id                     = module.vpc_primary.vpc_id
  subnet_ids                 = module.vpc_primary.database_subnets
  allowed_security_group_ids = [aws_security_group.app.id]
  allowed_cidr_blocks        = ["10.0.0.0/16"]

  instance_count = 3
  instance_class = "db.r6g.2xlarge"

  storage_encrypted = true
  kms_key_arn       = aws_kms_key.aurora.arn

  backup_retention_period      = 35
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  enable_deletion_protection = true
  skip_final_snapshot        = false

  iam_database_authentication_enabled = true
  enable_performance_insights         = true
  performance_insights_retention_period = 31
  enable_enhanced_monitoring          = true
  monitoring_interval                 = 15

  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Global Database
  enable_global_cluster      = true
  global_cluster_identifier  = "aurora-complete-global"

  # RDS Proxy
  enable_rds_proxy          = true
  proxy_idle_client_timeout = 3600
  proxy_require_tls         = true

  # Activity Stream
  enable_activity_stream = true
  activity_stream_mode   = "async"

  # Auto Scaling
  autoscaling_enabled      = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10
  autoscaling_target_cpu   = 60

  cluster_parameter_group_parameters = [
    {
      name         = "log_min_duration_statement"
      value        = "1000"
      apply_method = "immediate"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements,auto_explain"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_connections"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "immediate"
    }
  ]

  instance_parameter_group_parameters = [
    {
      name  = "log_rotation_age"
      value = "1440"
    }
  ]

  tags = {
    Environment   = "production"
    Project       = "enterprise-app"
    ManagedBy     = "terraform"
    CostCenter    = "engineering"
    DataClass     = "confidential"
    Compliance    = "soc2"
  }
}

################################################################################
# Outputs
################################################################################

output "cluster_endpoint" {
  description = "Primary cluster writer endpoint"
  value       = module.aurora_primary.cluster_endpoint
}

output "reader_endpoint" {
  description = "Primary cluster reader endpoint"
  value       = module.aurora_primary.reader_endpoint
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = module.aurora_primary.proxy_endpoint
}

output "proxy_read_only_endpoint" {
  description = "RDS Proxy read-only endpoint"
  value       = module.aurora_primary.proxy_read_only_endpoint
}

output "global_cluster_id" {
  description = "Global cluster identifier"
  value       = module.aurora_primary.global_cluster_id
}

output "activity_stream_kinesis" {
  description = "Kinesis stream for database activity"
  value       = module.aurora_primary.activity_stream_kinesis_stream_name
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.aurora_primary.security_group_id
}
