# Rice University URL Shortener & QR Studio: Institutional Transfer Manual

**Prepared For**: Rice University Office of Information Technology (OIT) & Institutional Communications  
**Repository**: `rice_url_shortener`  
**Current Staging Domain**: `go.thejambers.com`  
**Target Institutional Domain**: `link.rice.edu` / `go.rice.edu`  
**Version**: 1.0.0 (Production-Ready Architecture)

---

## 1. Executive Summary & Architecture

The **Rice URL Shortener & QR Studio** is an enterprise-grade web application engineered to provide Rice University students, faculty, and departments with branded, custom-alias URL shortening and dynamic, vector-rendered QR codes featuring official Rice University marks (Academic Crest/Shield, Rice Owl, and Old English R).

### Architecture Highlights
- **Frontend**: Flutter Web Single Page Application (SPA), styled according to Rice University brand guidelines (Rice Blue `#00205B`, Rice Gray `#7C7E7F`, typography matching Copernicus and Mallory).
- **Backend**: Containerized Serverpod (Dart) backend running on **AWS ECS Fargate** with automatic scaling.
- **Database**: Managed **AWS RDS PostgreSQL** with automated multi-AZ failover and daily snapshots.
- **Redirection Engine**: Ultra-fast HTTP handler (`/:code`) returning HTTP 301 (Permanent Redirect) for active links and HTTP 302 (Found) for expired/inactive links to a configurable fallback (`https://rice.edu`).
- **Infrastructure as Code (IaC)**: 100% automated via **Terraform**. Rice OIT can provision an isolated, enterprise-compliant environment in Rice's AWS account in minutes.

---

## 2. Institutional Handoff Checklist

| Step | Action Item | Responsible Party | Estimated Time |
|---|---|---|---|
| **Phase 1** | AWS Account & IAM Role Provisioning | Rice OIT Cloud Team | 30 minutes |
| **Phase 2** | Terraform Infrastructure Provisioning | Rice OIT Cloud Team | 15 minutes |
| **Phase 3** | Domain & DNS Delegation (`rice.edu`) | Rice OIT Network/DNS | 20 minutes |
| **Phase 4** | Rice NetID / Single Sign-On (SSO) Integration | Rice Identity Team | 1-2 hours |
| **Phase 5** | Container Image Build & ECR Push | DevOps / Engineering | 15 minutes |
| **Phase 6** | Static Frontend Deployment (CloudFront/S3) | DevOps / Engineering | 10 minutes |
| **Phase 7** | Data Migration & Verification | Engineering & OIT | 30 minutes |

---

## 3. Step-by-Step Migration Guide

### Phase 1: AWS Account & IAM Setup
1. Allocate an AWS Account under Rice University's AWS Organization.
2. Create an IAM User or Role with permissions to manage VPC, ECS, RDS, ALB, Route 53, and ACM.
3. Recommended IAM Policy: Attach `AdministratorAccess` (scoped to environment boundary) or custom least-privilege policy for Terraform execution.

### Phase 2: Terraform Infrastructure Deployment
The entire infrastructure resides in the `terraform/` directory.

1. Clone the repository into Rice's internal version control (e.g., Rice GitHub Enterprise or GitLab).
2. Navigate to `terraform/`:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Update `terraform.tfvars` with Rice parameters:
   ```hcl
   aws_region          = "us-east-1"
   environment         = "production"
   project_name        = "rice-url-shortener"
   domain_name         = "link.rice.edu" # or go.rice.edu
   db_name             = "riceshortener"
   db_username         = "rice_admin"
   db_password         = "YOUR_SECURE_GENERATED_PASSWORD"
   db_instance_class   = "db.t4g.micro" # or db.t4g.small for high traffic
   backend_cpu         = 512
   backend_memory      = 1024
   backend_count       = 2 # Multi-task redundancy
   ```
4. Initialize and apply:
   ```bash
   terraform init
   terraform plan -out=rice_plan.tfplan
   terraform apply rice_plan.tfplan
   ```
5. Terraform outputs the Application Load Balancer DNS name, RDS database endpoint, and CloudFront distribution domain.

### Phase 3: Domain & DNS Configuration (`rice.edu`)
1. **Subdomain Choice**: Recommended: `link.rice.edu` or `go.rice.edu`.
2. **DNS Configuration (Unified CloudFront Strategy)**:
   - If using Route 53 as DNS authority: Terraform automatically creates the A and AAAA record aliases pointing `link.rice.edu` (or `go.rice.edu`) directly to the CloudFront Unified CDN distribution, plus ACM DNS validation records in `us-east-1`.
   - If using external Rice DNS (Infoblox / BIND):
     - Create a CNAME or ALIAS record: `link.rice.edu` -> CloudFront distribution domain name (from Terraform output `cloudfront_domain_name`).
     - Add ACM DNS validation CNAME records to validate the SSL/TLS certificate in `us-east-1`.
3. SSL certificates are provisioned automatically via AWS Certificate Manager (ACM) in `us-east-1` with automatic annual renewal.

### Phase 4: Rice NetID / SSO Integration
Currently, the application supports Google OAuth restricted to `@rice.edu` domains. To integrate Rice NetID SSO:

1. **Option A: Google Workspace for Education (Zero-Code Switch)**:
   - Rice University Google accounts use NetID single sign-on automatically.
   - Ensure the Google OAuth client ID is registered in Rice's Google Cloud console.
2. **Option B: SAML 2.0 / Shibboleth (Enterprise SSO)**:
   - Configure Rice's Shibboleth IdP entity ID: `https://idp.rice.edu/idp/shibboleth`.
   - Update the backend authentication middleware in `server/lib/src/auth/` or frontend `AuthService` in `lib/data/services/auth_service.dart`.
   - Map SAML assertions: `netid` -> `userId`, `mail` -> `userEmail`, `displayName` -> `displayName`.

### Phase 5: Container Build & ECR Deployment
1. Authenticate Docker with Rice's AWS Elastic Container Registry (ECR):
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   ```
2. Build the production multi-stage container:
   ```bash
   docker build -t rice-url-shortener-server:latest -f server/Dockerfile .
   ```
3. Tag and push to ECR:
   ```bash
   docker tag rice-url-shortener-server:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/rice-url-shortener-server:latest
   docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/rice-url-shortener-server:latest
   ```
4. Update the ECS Service to trigger a zero-downtime rolling deployment:
   ```bash
   aws ecs update-service --cluster rice-url-shortener-production-cluster --service rice-url-shortener-production-service --force-new-deployment
   ```

### Phase 6: Static Frontend Deployment
1. Build the Flutter Web release bundle:
   ```bash
   flutter build web --release --base-href "/"
   ```
2. Sync the compiled bundle (`build/web/`) to the S3 bucket provisioned by Terraform:
   ```bash
   aws s3 sync build/web/ s3://<FRONTEND_S3_BUCKET_NAME>/ --delete
   ```
3. Invalidate CloudFront cache:
   ```bash
   aws cloudfront create-invalidation --distribution-id <CLOUDFRONT_DIST_ID> --paths "/*"
   ```

### Phase 7: Database Migration & Schema
The database tables are defined in `server/migrations/initial_schema.sql`.
1. The containerized backend runs migrations automatically on startup.
2. If migrating links from the temporary staging database or Firebase Firestore:
   - Run the included migration script: `dart run scripts/migrate_firestore_to_postgres.dart`.

---

## 4. Maintenance & Operations

### Monitoring & Alarms (AWS CloudWatch)
- **ALB Target Response Time**: Alert if 95th percentile latency > 200ms.
- **ECS Service Memory & CPU**: Auto-scale when CPU > 75% for 3 consecutive minutes.
- **RDS Storage & CPU**: Storage autoscaling is enabled up to 100 GB.
- **5xx HTTP Errors**: CloudWatch metric filter alerts if 5xx rate > 1%.

### Disaster Recovery & Backups
- **RDS Automated Snapshots**: Retained for 14 days with point-in-time recovery (PITR).
- **Multi-AZ Availability**: Can be toggled in `terraform.tfvars` (`multi_az = true`) for instant automated failover across availability zones.

---

## 5. Contact & Support
- **Initial Creator**: Jordan Szymczyk (`jordan24@gmail.com`)
- **Institution**: Rice University (`rice.edu`)
- **Documentation Ref**: [`README.md`](../README.md), [`TERRAFORM_GUIDE.md`](TERRAFORM_GUIDE.md), [`DOCKER_GUIDE.md`](DOCKER_GUIDE.md)

