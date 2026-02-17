# ------------------------------------------------------------------------------
# ElastiCache Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name_prefix = "${var.cluster_name}-redis-"
  description = "Security group for ElastiCache Redis ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-redis-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Redis from allowed security groups"
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value

  tags = { Name = "redis-ingress" }
}

resource "aws_vpc_security_group_ingress_rule" "redis_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "Redis from allowed CIDR blocks"
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = { Name = "redis-cidr-ingress" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "redis-all-egress" }
}
