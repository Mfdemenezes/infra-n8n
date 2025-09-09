# Outputs de rede
output "vpc_id" {
  description = "ID da VPC"
  value       = module.network.vpc_id
}

output "vpc_name" {
  description = "Nome da VPC"
  value       = module.network.vpc_name
}

output "subnet_id" {
  description = "ID da Subnet"
  value       = module.network.subnet_id
}

output "subnet_name" {
  description = "Nome da Subnet"
  value       = module.network.subnet_name
}

output "internet_gateway_name" {
  description = "Nome do Internet Gateway"
  value       = module.network.internet_gateway_name
}

output "route_table_name" {
  description = "Nome da Route Table"
  value       = module.network.route_table_name
}

# Outputs de segurança
output "security_group_id" {
  description = "ID do Security Group"
  value       = module.security_group.security_group_id
}

output "security_group_name" {
  description = "Nome do Security Group"
  value       = module.security_group.security_group_name
}

# Outputs do S3
output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = module.s3.bucket_arn
}

# Outputs das instâncias EC2
output "instance_ids" {
  description = "IDs das instâncias EC2"
  value       = module.ec2.instance_ids
}

output "instance_public_ips" {
  description = "IPs públicos das instâncias EC2"
  value       = module.ec2.instance_public_ips
}

output "instance_names" {
  description = "Nomes das instâncias EC2"
  value       = module.ec2.instance_names
}

# Outputs gerais
output "region" {
  description = "Região AWS"
  value       = var.region
}

output "environment" {
  description = "Ambiente"
  value       = var.environment
}

output "project_name" {
  description = "Nome do projeto"
  value       = var.ec2_name
}
