################################################################################
# Basic Aurora PostgreSQL Cluster
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "aurora-basic-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  tags = {
    Environment = "dev"
  }
}

module "aurora" {
  source = "../../"

  cluster_identifier = "aurora-basic"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"

  master_username             = "dbadmin"
  manage_master_user_password = true

  database_name = "myapp"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnets

  instance_count = 2
  instance_class = "db.r6g.large"

  backup_retention_period = 7

  enable_deletion_protection = false
  skip_final_snapshot        = true

  tags = {
    Environment = "dev"
    Project     = "basic-example"
  }
}

output "cluster_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "reader_endpoint" {
  value = module.aurora.reader_endpoint
}
