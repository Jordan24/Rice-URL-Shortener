# Rice URL Shortener: Terraform Infrastructure Deployment

This directory contains the production-grade **Terraform Infrastructure as Code (IaC)** configuration for deploying the Rice URL Shortener on Amazon Web Services (AWS).

---

## Architecture Provisioned

- **VPC & Subnets**: Multi-AZ Virtual Private Cloud across 2 availability zones with public and private subnets.
- **RDS PostgreSQL 16**: Relational database isolated in private subnets with automated backups, encryption at rest, and storage autoscaling.
- **ECS Fargate**: Serverless Docker container cluster running the Serverpod backend.
- **Application Load Balancer (ALB)**: Public load balancer handling HTTP-to-HTTPS redirects and forwarding traffic to containers.
- **Route 53 & ACM**: Automated SSL/TLS certificates and DNS management.
- **S3 & CloudFront**: Global edge-cached CDN for the Flutter Web frontend.

---

## Step-by-Step Execution Guide

### 1. Configure AWS CLI
Ensure your AWS CLI credentials are ready:
```bash
aws sts get-caller-identity
```

### 2. Prepare Variables
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` with:
- `domain_name`: `"go.thejambers.com"` (for testing) or `"go.rice.edu"` (for Rice University).
- `db_password`: A strong master database password.

### 3. Initialize Terraform
```bash
terraform init
```
This downloads the `hashicorp/aws` provider into `.terraform/`.

### 4. Validate Configuration
```bash
terraform fmt -check
terraform validate
```

### 5. Preview Changes (Plan)
```bash
terraform plan -out=tfplan
```
Review the list of resources to be created.

### 6. Apply Changes (Deploy)
```bash
terraform apply tfplan
```
Terraform will provision the complete AWS architecture in ~5 to 10 minutes.

### 7. Clean Up (Teardown)
When testing is complete and you want to remove all resources to avoid AWS billing:
```bash
terraform destroy
```

---

## File Reference

| File | Purpose |
|---|---|
| `versions.tf` | Required Terraform and AWS provider versions |
| `variables.tf` | Input variable declarations with descriptions and defaults |
| `main.tf` | Networking: VPC, subnets, route tables, internet gateway |
| `security.tf` | Security groups enforcing least-privilege isolation |
| `rds.tf` | Managed PostgreSQL database in private subnets |
| `ecs.tf` | ECS Cluster, task definition, Fargate service, ECR repository |
| `alb.tf` | Application Load Balancer and health check target groups |
| `route53_acm.tf` | Route 53 DNS records and ACM SSL certificate validation |
| `s3_frontend.tf` | Static web hosting on S3 with CloudFront CDN distribution |
| `outputs.tf` | Output values (ALB DNS name, database endpoint, CloudFront URL) |

