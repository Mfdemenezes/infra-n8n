terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# Criação da instância EC2
resource "aws_instance" "instance" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ec2_ssm[0].name : null
  #Perde o ebs antigo antes de criar o novo?
  lifecycle {
    create_before_destroy = true
  }
  # Configuração do volume raiz EBS  
  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = var.ebs_encrypted
    delete_on_termination = var.delete_on_termination

    tags = {
      Name = "${var.project_name}-${count.index}-root-volume"
    }

  }
  # User data script personalizado ou N8N
  user_data = var.user_data != "" ? var.user_data : templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    timezone     = var.generic_timezone
  })
  # Tags para a instância EC2
  tags = {
    Name = "${var.project_name}-${count.index}"
  }
}

# Role da EC2 para SSM (Session Manager)
resource "aws_iam_role" "ec2_ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.project_name}-ec2-ssm-role-${random_id.iam_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Gerar sufixo único para o IAM Role
resource "random_id" "iam_suffix" {
  byte_length = 4
}

# Attach the SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the EC2 instance profile
resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.project_name}-ec2-ssm-profile-${random_id.iam_suffix.hex}"
  role  = aws_iam_role.ec2_ssm[0].name
}