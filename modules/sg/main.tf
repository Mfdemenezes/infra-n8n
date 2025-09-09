# Security Group para EC2 (privado)
resource "aws_security_group" "sg" {
  name        = "${var.project_name}-ec2-security-group"
  description = "Security group para EC2 ${var.project_name}"
  vpc_id      = var.vpc_id

  # HTTP do ALB apenas
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
    description     = "HTTP from ALB"
  }

  # HTTPS do ALB apenas  
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
    description     = "HTTPS from ALB"
  }

  # N8N direct port (apenas para debug via SSM)
  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "N8N direct port from VPC only"
  }

  # SSH apenas da VPC (para SSM)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC only"
  }

  # Tráfego de saída para internet (via NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
    Type = "Private"
  }
}

# Security Group adicional para regras customizadas (compatibilidade)
resource "aws_security_group" "custom" {
  count       = length(var.ingress_rules) > 0 ? 1 : 0
  name        = "${var.project_name}-custom-security-group"
  description = "Security group customizado para ${var.project_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = {
    Name = "${var.project_name}-custom-sg"
  }
}
