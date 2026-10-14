---
name: terraform-aws
description: Best practices, modular architecture, resource patterns, state management, and deployment workflows for AWS infrastructure via Terraform.
---

# Terraform for AWS Skill Guide

Terraform provides declarative Infrastructure as Code (IaC) for AWS. This guide outlines institutional standards for architecture, state management, security, and resource design.

## 1. Modular Directory Structure
```
terraform/
├── versions.tf         # Terraform version constraint and AWS provider configuration
├── variables.tf        # Input variable definitions with types, descriptions, and defaults
├── outputs.tf          # Output values (ALB DNS, CloudFront URL, RDS endpoint)
├── main.tf             # Networking: VPC, subnets, route tables, internet gateway
├── security.tf         # Security groups with principle of least privilege
├── rds.tf              # PostgreSQL database in private isolated subnets
├── ecs.tf              # ECS Cluster, Fargate task definition, and service
├── alb.tf              # Application Load Balancer, listeners, and target groups
├── route53_acm.tf      # Route 53 DNS records and ACM SSL/TLS certificates
├── s3_frontend.tf      # Static S3 bucket + CloudFront CDN distribution
└── terraform.tfvars    # Environment-specific configuration values (git-ignored if containing secrets)
```

## 2. Core Best Practices
- **Least Privilege Security Groups**:
  - The database security group MUST only permit inbound port 5432 from the ECS backend task security group.
  - The ECS backend task security group MUST only permit inbound traffic from the ALB security group.
  - The ALB security group permits inbound 80/443 from `0.0.0.0/0`.
- **Secrets Management**:
  - Never hardcode database passwords in `.tf` files.
  - Use AWS Systems Manager Parameter Store or Secrets Manager, or pass via environment variables (`TF_VAR_db_password`).
- **State Storage**:
  - For production and institutional handoffs, configure an S3 backend with DynamoDB state locking to prevent concurrent modification.
- **Resource Tagging**:
  - Apply standard tags to all resources:
    - `Project`: `Rice-URL-Shortener`
    - `Environment`: `production` | `staging` | `development`
    - `Owner`: `Rice University OIT` | `Jordan Szymczyk`
    - `ManagedBy`: `Terraform`

## 3. Terraform Lifecycle
1. `terraform init`: Initializes providers and backend state storage.
2. `terraform validate`: Validates syntax and internal references.
3. `terraform plan -out=tfplan`: Computes execution plan and saves diff.
4. `terraform apply tfplan`: Applies the exact calculated diff to AWS.
5. `terraform destroy`: Tears down managed infrastructure.

