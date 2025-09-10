# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Security Group para ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Outbound para EC2
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "All traffic to VPC"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Target Group para N8N
resource "aws_lb_target_group" "n8n" {
  name     = "${var.project_name}-n8n-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    path                = "/healthz"
    matcher             = "200,404"
    port                = "80"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-n8n-tg"
  }
}

# Listener para ALB
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n.arn
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "n8n" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.n8n.arn
  target_id        = var.instance_ids[count.index]
  port             = 80
}
