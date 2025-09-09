output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.sg.id
}

output "security_group_name" {
  description = "Nome do Security Group"
  value       = aws_security_group.sg.name
}

output "security_group_arn" {
  description = "ARN do Security Group"
  value       = aws_security_group.sg.arn
}
