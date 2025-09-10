output "alb_arn" {
  description = "ARN do Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.n8n.arn
}

output "alb_security_group_id" {
  description = "ID do Security Group do ALB"
  value       = aws_security_group.alb.id
}
