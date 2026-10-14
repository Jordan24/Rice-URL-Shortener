# =============================================================================
# LOAD BALANCING: APPLICATION LOAD BALANCER (ALB)
# =============================================================================

resource "aws_lb" "main" {
  name               = "rice-shortener-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "rice-shortener-${var.environment}-alb"
  }
}

# Target Group for Redirect Engine, REST APIs, and Health Checks (Port 8081)
resource "aws_lb_target_group" "redirect" {
  name        = "rice-shortener-${var.environment}-tg"
  port        = var.redirect_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    port                = tostring(var.redirect_port)
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# HTTP Listener (Port 80):
# CloudFront connects to ALB on port 80 as its backend origin.
# Forwards traffic directly to the Serverpod ECS target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redirect.arn
  }
}

# HTTPS Listener (Port 443): Optional direct HTTPS listener when deploying in us-east-1.
# Note: In Option 2 (Unified Domain), CloudFront terminates SSL for public users and forwards
# to ALB on HTTP port 80. ALB HTTPS is only created when ALB is in the same region as the ACM cert (us-east-1).
resource "aws_lb_listener" "https" {
  count             = (var.enable_https && var.aws_region == "us-east-1") ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.create_route53_records ? aws_acm_certificate_validation.cert[0].certificate_arn : aws_acm_certificate.cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redirect.arn
  }
}
