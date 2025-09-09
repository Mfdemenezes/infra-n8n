variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "production"
}

variable "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  type        = string
}

variable "enable_waf" {
  description = "Habilitar AWS WAF para proteção adicional"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "Classe de preço do CloudFront"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200", 
      "PriceClass_100"
    ], var.price_class)
    error_message = "Price class deve ser PriceClass_All, PriceClass_200, ou PriceClass_100."
  }
}
