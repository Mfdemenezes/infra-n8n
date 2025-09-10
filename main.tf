# Configuração do provider
terraform {
  backend "s3" {
    bucket = "terraform-state-marcelo-menezes" # Mude para um nome único
    key    = "infra-n8n/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.region
}

# Módulo Network com Subnets Públicas e Privadas
module "network" {
  source = "./modules/network"

  project_name            = var.ec2_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr_a    = var.public_subnet_cidr_a
  public_subnet_cidr_b    = var.public_subnet_cidr_b
  private_subnet_cidr_a   = var.private_subnet_cidr_a
  private_subnet_cidr_b   = var.private_subnet_cidr_b
  availability_zone_a     = var.availability_zone_a
  availability_zone_b     = var.availability_zone_b
}

# Módulo Security Group para EC2 
module "security_group" {
  source = "./modules/sg"

  project_name   = var.ec2_name
  vpc_id         = module.network.vpc_id
  vpc_cidr       = var.vpc_cidr
  
  # Manter regras customizadas se houver
  ingress_rules = var.sg_ingress_rules
  egress_rules  = var.sg_egress_rules
}

# Módulo S3
module "s3" {
  source = "./modules/s3"

  project_name          = var.ec2_name
  environment           = var.environment
  enable_versioning     = var.s3_enable_versioning
  enable_encryption     = var.s3_enable_encryption
  block_public_access   = var.s3_block_public_access
  enable_bucket_policy  = var.s3_enable_bucket_policy
  bucket_name           = var.s3_bucket_name
}

# Módulo EC2 em Subnet Privada
module "ec2" {
  source = "./modules/ec2"

  project_name       = var.ec2_name
  instance_count     = var.ec2_count
  instance_type      = var.ec2_instance_type
  ami_id             = data.aws_ami.amazon_linux.id
  subnet_id          = module.network.private_subnet_a_id  # Usando subnet privada
  security_group_ids = [module.security_group.security_group_id]

  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_type       = var.ebs_volume_type
  ebs_encrypted         = var.ebs_encrypted
  delete_on_termination = true

  enable_ssm = var.enable_ssm
  user_data  = var.custom_user_data
}

# Application Load Balancer inline
resource "aws_lb" "main" {
  name               = "${var.ec2_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.network.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.ec2_name}-alb"
    Environment = var.environment
  }
}

# Security Group para ALB
resource "aws_security_group" "alb" {
  name        = "${var.ec2_name}-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = module.network.vpc_id

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
    Name = "${var.ec2_name}-alb-sg"
  }
}

# Target Group para N8N
resource "aws_lb_target_group" "n8n" {
  name     = "${var.ec2_name}-n8n-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    path                = "/"
    matcher             = "200,404"
    port                = "80"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.ec2_name}-n8n-tg"
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
  count            = length(module.ec2.instance_ids)
  target_group_arn = aws_lb_target_group.n8n.arn
  target_id        = module.ec2.instance_ids[count.index]
  port             = 80
}

# # Módulo CloudFront Distribution (desabilitado por enquanto)
# module "cloudfront" {
#   source = "./modules/cloudfront"

#   project_name    = var.ec2_name
#   environment     = var.environment
#   alb_dns_name    = module.alb.alb_dns_name
#   enable_waf      = var.enable_cloudfront_waf
#   price_class     = var.cloudfront_price_class
# }
