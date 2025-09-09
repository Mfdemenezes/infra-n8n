output "cloudfront_domain_name" {
  description = "Domain name do CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID do CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_arn" {
  description = "ARN do CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_zone_id" {
  description = "Zone ID do CloudFront distribution"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cloudfront_url" {
  description = "URL completa do CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "waf_arn" {
  description = "ARN do WAF (se habilitado)"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}
