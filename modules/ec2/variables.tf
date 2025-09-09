variable "project_name" {
  description = "Nome do projeto para tags dos recursos"
  type        = string
}

variable "instance_count" {
  description = "Número de instâncias EC2 a serem criadas"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI para a instância EC2"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde criar as instâncias"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs dos security groups"
  type        = list(string)
}

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

variable "delete_on_termination" {
  description = "Deletar volume EBS quando instância for terminada"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "Script de user data personalizado"
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "Habilitar SSM Session Manager"
  type        = bool
  default     = true
}
