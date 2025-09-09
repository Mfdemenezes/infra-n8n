output "security_group_id" {
  description = "ID do Security Group principal (EC2)"
  value       = aws_security_group.sg.id
}

output "security_group_name" {
  description = "Nome do Security Group principal (EC2)"
  value       = aws_security_group.sg.name
}

output "security_group_arn" {
  description = "ARN do Security Group principal (EC2)"
  value       = aws_security_group.sg.arn
}

output "custom_security_group_id" {
  description = "ID do Security Group customizado (se criado)"
  value       = length(aws_security_group.custom) > 0 ? aws_security_group.custom[0].id : null
}

output "security_group_ids" {
  description = "Lista de todos os IDs dos Security Groups"
  value = compact([
    aws_security_group.sg.id,
    length(aws_security_group.custom) > 0 ? aws_security_group.custom[0].id : null
  ])
}
