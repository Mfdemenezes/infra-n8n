# Configuração do provider
terraform {
  backend "s3" {
    bucket = "terraform-state-marcelo-menezes" # Mude para um nome único
    key    = "udemy-06/terraform.tfstate"
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

# Módulo Network
module "network" {
  source = "./modules/network"

  project_name            = var.ec2_name
  vpc_cidr                = var.vpc_cidr
  subnet_cidr             = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

# Módulo Security Group
module "security_group" {
  source = "./modules/sg"

  project_name = var.ec2_name
  vpc_id       = module.network.vpc_id

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

# Módulo EC2
module "ec2" {
  source = "./modules/ec2"

  project_name       = var.ec2_name
  instance_count     = var.ec2_count
  instance_type      = var.ec2_instance_type
  ami_id             = data.aws_ami.amazon_linux.id
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.security_group.security_group_id]

  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_type       = var.ebs_volume_type
  ebs_encrypted         = var.ebs_encrypted
  delete_on_termination = true

  enable_ssm = var.enable_ssm
  user_data  = var.custom_user_data
}
