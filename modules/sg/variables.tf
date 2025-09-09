variable "project_name" {
  description = "Nome do projeto para tags dos recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde criar o security group"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "alb_security_group_ids" {
  description = "IDs dos security groups do ALB"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "Lista de regras de entrada customizadas (opcional)"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "egress_rules" {
  description = "Lista de regras de saída customizadas (opcional)"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}
