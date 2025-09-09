output "instance_ids" {
  description = "IDs das instâncias EC2"
  value       = aws_instance.instance[*].id
}

output "instance_public_ips" {
  description = "IPs públicos das instâncias EC2"
  value       = aws_instance.instance[*].public_ip
}

output "instance_private_ips" {
  description = "IPs privados das instâncias EC2"
  value       = aws_instance.instance[*].private_ip
}

output "instance_names" {
  description = "Nomes das instâncias EC2"
  value       = aws_instance.instance[*].tags.Name
}

output "iam_role_arn" {
  description = "ARN do IAM Role para SSM"
  value       = var.enable_ssm ? aws_iam_role.ec2_ssm[0].arn : null
}

output "instance_profile_name" {
  description = "Nome do instance profile"
  value       = var.enable_ssm ? aws_iam_instance_profile.ec2_ssm[0].name : null
}
