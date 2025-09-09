output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_name" {
  description = "Nome da VPC"
  value       = aws_vpc.main.tags.Name
}

output "subnet_id" {
  description = "ID da Subnet"
  value       = aws_subnet.main.id
}

output "subnet_name" {
  description = "Nome da Subnet"
  value       = aws_subnet.main.tags.Name
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.internet_gateway.id
}

output "internet_gateway_name" {
  description = "Nome do Internet Gateway"
  value       = aws_internet_gateway.internet_gateway.tags.Name
}

output "route_table_id" {
  description = "ID da Route Table"
  value       = aws_route_table.route_table.id
}

output "route_table_name" {
  description = "Nome da Route Table"
  value       = aws_route_table.route_table.tags.Name
}
