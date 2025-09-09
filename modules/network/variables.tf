variable "project_name" {
  description = "Nome do projeto para tags dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block para a subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone para a subnet"
  type        = string
  default     = ""
}

variable "map_public_ip_on_launch" {
  description = "Mapear IP público automaticamente nas instâncias"
  type        = bool
  default     = true
}
