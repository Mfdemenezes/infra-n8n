variable "project_name" {
  description = "Nome do projeto para tags dos recursos"
  type        = string
}

variable "bucket_name" {
  description = "Nome específico do bucket"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod, staging)"
  type        = string
  default     = "development"
}

variable "enable_versioning" {
  description = "Habilitar versionamento no bucket S3"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Habilitar criptografia no bucket S3"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Bloquear acesso público ao bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_policy" {
  description = "Habilitar política personalizada do bucket (SSL only)"
  type        = bool
  default     = true
}
