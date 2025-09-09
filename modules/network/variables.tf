variable "project_name" {
  description = "Nome do projeto para tags dos recursos"
  type        = string
}

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

variable "map_public_ip_on_launch" {
  description = "Mapear IP público automaticamente nas instâncias"
  type        = bool
  default     = false  # Mudando para false por segurança
}
