# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "${var.project_name}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} N8N Distribution"

  # Cache behavior para aplicação N8N
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-alb-origin"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Origin", "Referer"]
      
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
  }

  # Cache behavior específico para API endpoints
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-alb-origin"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["*"]
      
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Cache behavior para health check
  ordered_cache_behavior {
    path_pattern           = "/healthz"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-alb-origin"
    compress               = false

    forwarded_values {
      query_string = false
      headers      = []
      
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 300
  }

  # Configurações de geo-restrição (opcional)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Certificado SSL padrão do CloudFront
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Web Application Firewall (opcional)
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null

  # Configurações de preço
  price_class = var.price_class

  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
}

# WAF v2 para proteção adicional (opcional)
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0
  
  name  = "${var.project_name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regra para rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }

    action {
      block {}
    }
  }

  # Regra para AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled    = true
    }

    action {
      allow {}
    }
  }

  tags = {
    Name = "${var.project_name}-waf"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.project_name}-waf"
    sampled_requests_enabled    = true
  }
}
