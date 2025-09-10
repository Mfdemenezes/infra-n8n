variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "production"
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas para o ALB"
  type        = list(string)
}

variable "instance_ids" {
  description = "IDs das instâncias EC2 para o target group"
  type        = list(string)
}