# Configurações básicas
variable "region" {
  description = "Região AWS para criar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (dev, prod, staging)"
  type        = string
  default     = "development"
}

# Configurações EC2
variable "ec2_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ec2_count" {
  description = "Número de instâncias EC2 a serem criadas"
  type        = number
  default     = 1
}

variable "ec2_name" {
  description = "Nome do projeto/instâncias EC2"
  type        = string
  default     = "minha-instancia"
}

variable "enable_ssm" {
  description = "Habilitar SSM Session Manager"
  type        = bool
  default     = true
}

variable "custom_user_data" {
  description = "Script personalizado de user data"
  type        = string
  default     = ""
}

# Configurações de rede
variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets Públicas (para ALB)
variable "public_subnet_cidr_a" {
  description = "CIDR block para a subnet pública A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block para a subnet pública B"
  type        = string
  default     = "10.0.2.0/24"
}

# Subnets Privadas (para EC2)
variable "private_subnet_cidr_a" {
  description = "CIDR block para a subnet privada A"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block para a subnet privada B"
  type        = string
  default     = "10.0.4.0/24"
}

# Availability Zones
variable "availability_zone_a" {
  description = "Availability Zone A"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Availability Zone B"
  type        = string
  default     = "us-east-1b"
}

# Configurações EBS
variable "ebs_volume_size" {
  description = "Tamanho do volume EBS em GB"
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "Tipo do volume EBS"
  type        = string
  default     = "gp3"
}

variable "ebs_encrypted" {
  description = "Criptografar o volume EBS"
  type        = bool
  default     = true
}

# Configurações Security Group
variable "sg_ingress_rules" {
  description = "Regras de entrada do security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    }
  ]
}

variable "sg_egress_rules" {
  description = "Regras de saída do security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound traffic"
    }
  ]
}

# Configurações S3
variable "s3_bucket_name" {
  description = "Nome específico do bucket S3 (deixe vazio para gerar automaticamente)"
  type        = string
  default     = ""
}

variable "s3_enable_versioning" {
  description = "Habilitar versionamento no S3"
  type        = bool
  default     = false
}

variable "s3_enable_encryption" {
  description = "Habilitar criptografia no S3"
  type        = bool
  default     = true
}

variable "s3_block_public_access" {
  description = "Bloquear acesso público ao S3"
  type        = bool
  default     = true
}

variable "s3_enable_bucket_policy" {
  description = "Habilitar política personalizada do bucket S3 (SSL only)"
  type        = bool
  default     = true
}

# Compatibilidade com versão anterior
variable "subnet_cidr" {
  description = "CIDR block para a subnet (compatibilidade)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone (compatibilidade)"
  type        = string
  default     = "us-east-1a"
}

# Configurações CloudFront
variable "enable_cloudfront_waf" {
  description = "Habilitar AWS WAF no CloudFront para proteção adicional"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "Classe de preço do CloudFront (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}
