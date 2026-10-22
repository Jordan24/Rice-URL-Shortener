variable "aws_region" {
  description = "AWS region for provisioning resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging, dev)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name prefix used for resource naming"
  type        = string
  default     = "rice-url-shortener"
}

variable "domain_name" {
  description = "Custom domain name for the URL shortener (e.g. go.thejambers.com or go.rice.edu)"
  type        = string
  default     = "go.thejambers.com"
}

variable "create_route53_records" {
  description = "Whether to manage Route 53 DNS records in AWS. Set false if using external DNS (Rice Infoblox or Namecheap)"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS listener with ACM certificate. Set false for initial HTTP-only testing on ALB DNS without custom SSL certificate."
  type        = bool
  default     = true
}

variable "attach_custom_domain" {
  description = "Attach custom domain alias and ACM certificate to CloudFront. Set false on first apply with external DNS (Namecheap) until ACM DNS validation CNAME is created and issued."
  type        = bool
  default     = true
}

variable "allow_search_indexing" {
  description = "Whether search engines are allowed to index the application. Set false (default) to attach X-Robots-Tag: noindex, nofollow, noarchive headers at the CloudFront edge."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "riceshortener"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "rice_admin"
}

variable "db_password" {
  description = "PostgreSQL master password (must be at least 8 characters)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class (e.g. db.t4g.micro for free tier, db.t4g.small for production)"
  type        = string
  default     = "db.t4g.micro"
}

variable "multi_az_db" {
  description = "Enable Multi-AZ failover for high availability in production"
  type        = bool
  default     = false
}

variable "backend_cpu" {
  description = "vCPU units allocated for each Serverpod Fargate container (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory in MB allocated for each Serverpod Fargate container"
  type        = number
  default     = 1024
}

variable "backend_count" {
  description = "Number of backend container task replicas to maintain"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Serverpod API container port"
  type        = number
  default     = 8080
}

variable "redirect_port" {
  description = "Serverpod HTTP redirection and health check port"
  type        = number
  default     = 8081
}

# =============================================================================
# SAML 2.0 / SHIBBOLETH SSO VARIABLES (RICE NETID SSO READINESS)
# =============================================================================

variable "enable_saml_sso" {
  description = "Enable SAML 2.0 Identity Provider federation for Rice NetID SSO"
  type        = bool
  default     = false
}

variable "saml_provider_name" {
  description = "SAML Identity Provider name for Rice NetID Shibboleth"
  type        = string
  default     = "Rice-NetID-SSO"
}

variable "saml_metadata_url" {
  description = "SAML metadata URL for Rice Shibboleth IdP (e.g. https://idp.rice.edu/idp/shibboleth)"
  type        = string
  default     = ""
}

variable "saml_metadata_file" {
  description = "Optional path to SAML XML metadata file if URL is on internal Rice network"
  type        = string
  default     = ""
}

