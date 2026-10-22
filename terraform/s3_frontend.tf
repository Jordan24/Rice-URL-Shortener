# =============================================================================
# UNIFIED FRONTEND & REDIRECTION CDN: S3 BUCKET & CLOUDFRONT DISTRIBUTION
# Dual-Mode Strategy Option 2: Unified Domain (go.thejambers.com / go.rice.edu)
# =============================================================================

# S3 Bucket for Flutter Web compiled release assets
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-${var.environment}-frontend"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-frontend-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control (OAC) to secure S3 bucket
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for Flutter Web S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Response Headers Policy for Search Engine Indexing Control
resource "aws_cloudfront_response_headers_policy" "robots" {
  name    = "${var.project_name}-${var.environment}-robots-policy"
  comment = "Controls X-Robots-Tag header for search engine indexing"

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      override = true
      value    = var.allow_search_indexing ? "index, follow" : "noindex, nofollow, noarchive"
    }
  }
}

# CloudFront Distribution for global unified CDN (Frontend S3 + Serverpod ALB)
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = (var.enable_https && (var.create_route53_records || var.attach_custom_domain)) ? [var.domain_name] : []

  # Origin 1: S3 Bucket hosting compiled Flutter Web assets
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Origin 2: Application Load Balancer for Serverpod backend redirect engine and REST API
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "AlbOrigin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  # ---------------------------------------------------------------------------
  # DEFAULT CACHE BEHAVIOR: Serverpod Backend Redirection Engine (/*)
  # Dynamic redirects (/:code -> 301/302) are routed to Serverpod with no caching
  # to preserve real-time analytics and instant target changes.
  # ---------------------------------------------------------------------------
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "AlbOrigin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = true
      headers      = ["Host", "User-Agent", "Referer", "Accept", "Authorization"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # ---------------------------------------------------------------------------
  # ORDERED CACHE BEHAVIORS
  # Precedence evaluated from first to last:
  # ---------------------------------------------------------------------------

  # 1. Backend REST API routes (/api/*)
  ordered_cache_behavior {
    path_pattern               = "/api/*"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "AlbOrigin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Content-Type", "Accept", "Origin"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # 2. Backend Health check route (/health)
  ordered_cache_behavior {
    path_pattern               = "/health"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "AlbOrigin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = false
  }

  # 3. Flutter Web HTML Entry Point (/index.html) -> S3
  ordered_cache_behavior {
    path_pattern               = "/index.html"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # 4. Flutter Web Engine & JS Bundles (/flutter* & /main.dart.js*) -> S3
  ordered_cache_behavior {
    path_pattern               = "/flutter*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern               = "/main.dart*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800
    compress               = true
  }

  # 5. Flutter Web Static Assets (/assets/*) -> S3
  ordered_cache_behavior {
    path_pattern               = "/assets/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800
    compress               = true
  }

  # 6. CanvasKit WebAssembly Engine (/canvaskit/*) -> S3
  ordered_cache_behavior {
    path_pattern               = "/canvaskit/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 604800
    max_ttl                = 2592000
    compress               = true
  }

  # 7. App Icons (/icons/*) -> S3
  ordered_cache_behavior {
    path_pattern               = "/icons/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800
    compress               = true
  }

  # 8. Web App Manifest (/manifest.json) -> S3
  ordered_cache_behavior {
    path_pattern               = "/manifest.json"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # 9. Favicon & Web Icons (/favicon*) -> S3
  ordered_cache_behavior {
    path_pattern               = "/favicon*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800
    compress               = true
  }

  # 10. Version File (/version.json) -> S3
  ordered_cache_behavior {
    path_pattern               = "/version.json"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 300
    compress               = true
  }

  # 11. Flutter SPA Navigation Routes (/app*, /dashboard*, /login*) -> S3 (SPA fallback to index.html)
  ordered_cache_behavior {
    path_pattern               = "/app*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern               = "/dashboard*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern               = "/login*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # 12. Static 404 Error Page (/404.html) -> S3
  ordered_cache_behavior {
    path_pattern               = "/404.html"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # 13. Search Engine Crawler Instructions (/robots.txt) -> S3
  ordered_cache_behavior {
    path_pattern               = "/robots.txt"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3Origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.robots.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # SPA Routing: Redirect 404s and 403s to index.html with HTTP 200 for HTML5 path routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = (var.enable_https && (var.create_route53_records || var.attach_custom_domain)) ? (var.create_route53_records ? aws_acm_certificate_validation.cert[0].certificate_arn : aws_acm_certificate.cert[0].arn) : null
    cloudfront_default_certificate = (var.enable_https && (var.create_route53_records || var.attach_custom_domain)) ? false : true
    ssl_support_method             = (var.enable_https && (var.create_route53_records || var.attach_custom_domain)) ? "sni-only" : null
    minimum_protocol_version       = (var.enable_https && (var.create_route53_records || var.attach_custom_domain)) ? "TLSv1.2_2021" : null
  }

  tags = {
    Name = "${var.project_name}-unified-cdn"
  }
}

# Bucket policy allowing CloudFront OAC read access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
