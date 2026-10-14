output "alb_dns_name" {
  description = "Application Load Balancer DNS name (backend origin for CloudFront)"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "ecr_repository_url" {
  description = "Elastic Container Registry (ECR) URL for pushing Docker images"
  value       = aws_ecr_repository.server.repository_url
}

output "frontend_s3_bucket" {
  description = "S3 bucket name hosting the compiled Flutter Web frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (used for CI/CD cache invalidation)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront CDN domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "application_url" {
  description = "Target public unified application URL"
  value       = "https://${var.domain_name}"
}

output "acm_validation_records" {
  description = "DNS validation CNAME records to add to Namecheap (or your DNS registrar) for SSL certification"
  value = var.enable_https ? [
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  ] : []
}

