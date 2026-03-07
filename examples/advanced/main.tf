################################################################################
# Advanced Aurora MySQL with RDS Proxy
################################################################################

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "aurora-advanced-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  tags = {
    Environment = "staging"
  }
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "app-sg"
  }
}

module "aurora" {
  source = "../../"

  cluster_identifier = "aurora-advanced"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.05.2"

  cluster_parameter_group_family = "aurora-mysql8.0"

  master_username             = "dbadmin"
  manage_master_user_password = true

  database_name = "myapp"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.database_subnets
  allowed_security_group_ids = [aws_security_group.app.id]

  instance_count = 3
  instance_class = "db.r6g.xlarge"

  storage_encrypted       = true
  backup_retention_period = 14

  enable_deletion_protection = true
  skip_final_snapshot        = false

  iam_database_authentication_enabled = true
  enable_performance_insights         = true
  enable_enhanced_monitoring          = true
  monitoring_interval                 = 30

  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]

  # RDS Proxy
  enable_rds_proxy         = true
  proxy_idle_client_timeout = 1800
  proxy_require_tls        = true

  # Auto Scaling
  autoscaling_enabled      = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 8
  autoscaling_target_cpu   = 65

  cluster_parameter_group_parameters = [
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "collation_server"
      value = "utf8mb4_unicode_ci"
    }
  ]

  tags = {
    Environment = "staging"
    Project     = "advanced-example"
    ManagedBy   = "terraform"
  }
}

output "cluster_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "proxy_endpoint" {
  value = module.aurora.proxy_endpoint
}

output "proxy_read_only_endpoint" {
  value = module.aurora.proxy_read_only_endpoint
}
