# =============================================================================
# DOMAIN & SSL: ROUTE 53 DNS & AWS CERTIFICATE MANAGER (ACM)
# =============================================================================

# Request automated public SSL/TLS Certificate for custom domain in us-east-1 (CloudFront requirement)
resource "aws_acm_certificate" "cert" {
  count             = var.enable_https ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# Lookup existing Route 53 Hosted Zone if manage records is enabled
data "aws_route53_zone" "primary" {
  count        = var.create_route53_records ? 1 : 0
  name         = join(".", slice(split(".", var.domain_name), length(split(".", var.domain_name)) - 2, length(split(".", var.domain_name))))
  private_zone = false
}

# DNS Validation CNAME record in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = (var.enable_https && var.create_route53_records) ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary[0].zone_id
}

# Certificate Validation Resource (only waits automatically if Route 53 manages the zone)
resource "aws_acm_certificate_validation" "cert" {
  count                   = (var.enable_https && var.create_route53_records) ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# A-Record Alias pointing custom domain directly to the CloudFront Unified CDN
resource "aws_route53_record" "apex" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA-Record IPv6 Alias pointing custom domain directly to CloudFront Unified CDN
resource "aws_route53_record" "apex_ipv6" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
