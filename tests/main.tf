module "test" {
  source = "../"

  cluster_identifier = "test-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  engine_mode        = "provisioned"

  # Authentication
  master_username            = "testadmin"
  manage_master_user_password = true

  # Database
  database_name = "testdb"
  port          = 5432

  # Network
  vpc_id     = "vpc-0abc1234def567890"
  subnet_ids = ["subnet-0abc1234def567890", "subnet-0abc1234def567891"]

  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Instances
  instance_count = 2
  instance_class = "db.r6g.large"

  # Encryption
  storage_encrypted = true

  # Backup & Maintenance
  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  # Protection
  enable_deletion_protection = false
  skip_final_snapshot        = true

  # Authentication & Security
  iam_database_authentication_enabled = true

  # Performance & Monitoring
  enable_performance_insights            = true
  performance_insights_retention_period  = 7
  enable_enhanced_monitoring             = true
  monitoring_interval                    = 60
  enabled_cloudwatch_logs_exports        = ["postgresql"]

  tags = {
    Project     = "aurora-test"
    Environment = "test"
  }
}
