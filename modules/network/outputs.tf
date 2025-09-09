output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_name" {
  description = "Nome da VPC"
  value       = aws_vpc.main.tags.Name
}

# Outputs das Subnets Públicas
output "public_subnet_ids" {
  description = "IDs das Subnets Públicas"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "public_subnet_a_id" {
  description = "ID da Subnet Pública A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID da Subnet Pública B"
  value       = aws_subnet.public_b.id
}

# Outputs das Subnets Privadas
output "private_subnet_ids" {
  description = "IDs das Subnets Privadas"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "private_subnet_a_id" {
  description = "ID da Subnet Privada A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID da Subnet Privada B"
  value       = aws_subnet.private_b.id
}

# Compatibilidade com versão anterior
output "subnet_id" {
  description = "ID da Subnet (compatibilidade - usando subnet privada A)"
  value       = aws_subnet.private_a.id
}

output "subnet_name" {
  description = "Nome da Subnet (compatibilidade)"
  value       = aws_subnet.private_a.tags.Name
}

# Outros outputs importantes
output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = aws_nat_gateway.nat_gateway.id
}

output "availability_zones" {
  description = "Availability Zones utilizadas"
  value       = [aws_subnet.public_a.availability_zone, aws_subnet.public_b.availability_zone]
}
