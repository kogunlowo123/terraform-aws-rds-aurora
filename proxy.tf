################################################################################
# RDS Proxy IAM Role
################################################################################

resource "aws_iam_role" "proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name        = "${var.cluster_identifier}-rds-proxy-role"
  description = "IAM role for RDS Proxy to access Secrets Manager for ${var.cluster_identifier}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-rds-proxy-role"
  })
}

resource "aws_iam_role_policy" "proxy_secrets" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.cluster_identifier}-rds-proxy-secrets"
  role = aws_iam_role.proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/aws:rds:cluster-identifier" = var.cluster_identifier
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : ["*"]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

################################################################################
# RDS Proxy
################################################################################

resource "aws_db_proxy" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = "${var.cluster_identifier}-proxy"
  debug_logging          = false
  engine_family          = var.engine == "aurora-mysql" ? "MYSQL" : "POSTGRESQL"
  idle_client_timeout    = var.proxy_idle_client_timeout
  require_tls            = var.proxy_require_tls
  role_arn               = aws_iam_role.proxy[0].arn
  vpc_security_group_ids = [aws_security_group.this.id]
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "Secrets Manager authentication for ${var.cluster_identifier}"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_rds_cluster.this.master_user_secret[0].secret_arn
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-proxy"
  })
}

################################################################################
# RDS Proxy Default Target Group
################################################################################

resource "aws_db_proxy_default_target_group" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

################################################################################
# RDS Proxy Target
################################################################################

resource "aws_db_proxy_target" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name         = aws_db_proxy.this[0].name
  target_group_name     = aws_db_proxy_default_target_group.this[0].name
  db_cluster_identifier = aws_rds_cluster.this.id
}

################################################################################
# RDS Proxy Read-Only Endpoint
################################################################################

resource "aws_db_proxy_endpoint" "read_only" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name          = aws_db_proxy.this[0].name
  db_proxy_endpoint_name = "${var.cluster_identifier}-proxy-ro"
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.this.id]
  target_role            = "READ_ONLY"

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-proxy-ro"
  })
}
