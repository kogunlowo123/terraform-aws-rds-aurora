################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for Aurora cluster ${var.cluster_identifier}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Ingress Rules - Security Group Sources
################################################################################

resource "aws_security_group_rule" "ingress_security_groups" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = coalesce(var.port, var.engine == "aurora-mysql" ? 3306 : 5432)
  to_port                  = coalesce(var.port, var.engine == "aurora-mysql" ? 3306 : 5432)
  protocol                 = "tcp"
  description              = "Allow inbound from security group ${var.allowed_security_group_ids[count.index]}"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this.id
}

################################################################################
# Ingress Rules - CIDR Block Sources
################################################################################

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = coalesce(var.port, var.engine == "aurora-mysql" ? 3306 : 5432)
  to_port           = coalesce(var.port, var.engine == "aurora-mysql" ? 3306 : 5432)
  protocol          = "tcp"
  description       = "Allow inbound from CIDR blocks"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this.id
}

################################################################################
# Egress Rule
################################################################################

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow all outbound traffic"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}
