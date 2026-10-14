# AWS Setup Guide for Jordan: From Zero to Cloud Deployment

This guide covers **what you need to do yourself (which requires a credit card and AWS sign-in) and how the code deploys on `go.thejambers.com` using the Unified Domain strategy via AWS CloudFront**.

---

## 1. What Jordan Needs to Do Yourself (Prerequisites)

Because AWS accounts require identity verification and billing information, follow these steps:

### Step 1: Create an AWS Account (Free Tier)
1. Go to [https://aws.amazon.com](https://aws.amazon.com) and click **"Create an AWS Account"**.
2. Enter your email and account name.
3. Choose the **Free Plan** (AWS gives you 12 months of free tier access, including 750 hours/month of micro database, S3 storage, and CloudFront bandwidth).
4. Complete phone verification and add a payment method.

### Step 2: Set Up a $5 Billing Alert (Important for Safety!)
1. Log into the AWS Management Console as the Root user.
2. In the top search bar, type **Billing and Cost Management**.
3. In the left navigation, select **Budgets** (or **Billing Preferences**).
4. Click **Create budget** -> Choose **Zero spend budget** or set a threshold (e.g. $5.00/month).
5. Add your email address (`jordan24@gmail.com`). AWS will email you immediately if your usage ever exceeds the free tier.

### Step 3: Create an IAM User for Terraform & GitHub Actions
Never use your root account for daily development or CI/CD deployments.
1. In the console search bar, type **IAM** (Identity and Access Management).
2. Click **Users** -> **Create user**.
3. User name: `terraform-admin`.
4. Do *not* grant console access (this user is only for CLI/Terraform/GitHub Actions). Click **Next**.
5. Set permissions: Select **Attach policies directly**.
6. Check **AdministratorAccess** (gives Terraform full rights to create VPCs, databases, and containers). Click **Next** -> **Create user**.
7. Click on your newly created `terraform-admin` user.
8. Go to the **Security credentials** tab.
9. Scroll down to **Access keys** and click **Create access key**.
10. Select **Command Line Interface (CLI)**. Check the confirmation box and click **Next**.
11. Copy your:
    - **Access Key ID** (e.g. `AKIAIOSFODNN7EXAMPLE`)
    - **Secret Access Key** (e.g. `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
    *(Save these in a password manager. AWS will never show the secret key again!)*

### Step 4: Install and Configure AWS CLI on Your Mac
Open your macOS Terminal and run:
```bash
# 1. Install AWS CLI using Homebrew
brew install awscli

# 2. Configure credentials
aws configure
```
When prompted, enter:
- **AWS Access Key ID**: Paste the key from Step 3.
- **AWS Secret Access Key**: Paste the secret from Step 3.
- **Default region name**: `us-east-1`
- **Default output format**: `json`

Verify it is connected:
```bash
aws sts get-caller-identity
```
You should see your account ID and user ARN!

---

## 2. Unified Domain Architecture via AWS CloudFront (`go.thejambers.com`)

The infrastructure uses **Unified Domain via AWS CloudFront** (Option 2):

### How the Unified Domain Works:
All traffic for `go.thejambers.com` enters AWS through **AWS CloudFront CDN**:
1. **Frontend UI & Static Assets**:
   - CloudFront routes `/` (via `default_root_object = "index.html"`), `/index.html`, `/flutter*`, `/main.dart.js*`, `/assets/*`, `/canvaskit/*`, `/icons/*`, `/manifest.json`, and SPA paths (`/app*`, `/dashboard*`, `/login*`) directly to the **S3 Bucket** hosting compiled Flutter Web assets.
2. **Backend API & Dynamic Redirection**:
   - CloudFront routes REST API RPCs (`/api/*`) and health checks (`/health`) to the **Application Load Balancer (ALB)** connected to the Serverpod container tasks.
   - CloudFront routes `/*` (all short links like `go.thejambers.com/campanile` or `go.thejambers.com/owl`) dynamically to the Serverpod ALB with zero caching (`min_ttl = 0`), ensuring instantaneous HTTP 301/302 redirects and atomic PostgreSQL click tracking.
3. **Route 53 DNS**:
   - Route 53 A and AAAA Alias records point `go.thejambers.com` directly to the CloudFront distribution with zero DNS lookup latency.

---

## 3. Running Terraform for the First Time

Once your AWS CLI is configured:
```bash
cd "/Users/jordan/Code/Projects/Rice URL Shortener/terraform"

# Copy the example variables
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and set:
```hcl
aws_region    = "us-east-1"
environment   = "production"
domain_name   = "go.thejambers.com"
db_password   = "YOUR_STRONG_PASSWORD_HERE"
```

Now run the 3 commands:
```bash
# 1. Download provider plugins
terraform init

# 2. Review what AWS will build
terraform plan

# 3. Build it!
terraform apply
```

Type `yes` when prompted. Within a few minutes, AWS will provision your VPC, RDS PostgreSQL database, ECS container cluster, S3 frontend bucket, and Unified CloudFront CDN distribution.

---

## 4. CI/CD Automated Deployment

The GitHub Actions workflow (`.github/workflows/deploy.yml`) is fully configured for automated continuous deployment:
1. In your GitHub repository settings, navigate to **Settings** -> **Secrets and variables** -> **Actions**.
2. Add the following repository secrets:
   - `AWS_ACCESS_KEY_ID`: IAM user access key from Step 3.
   - `AWS_SECRET_ACCESS_KEY`: IAM user secret key from Step 3.
   - `AWS_REGION`: `us-east-1`
   - `AWS_S3_BUCKET`: `rice-url-shortener-production-frontend` (from `terraform output frontend_s3_bucket`)
   - `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront ID (from `terraform output cloudfront_distribution_id`)
3. On every `git push` to `main`:
   - Runs Flutter web unit tests and Serverpod backend unit tests.
   - Compiles Flutter Web release.
   - Automatically syncs release files to the S3 bucket (`aws s3 sync build/web s3://... --delete`).
   - Invalidates CloudFront distribution cache (`aws cloudfront create-invalidation ...`).
   - Updates GitHub Pages mirror as backup with `cname: go.thejambers.com`.

---

## 5. What We Have Built & What's Next
- You have complete Terraform infrastructure files in `terraform/`.
- You have a multi-stage Docker container in `server/Dockerfile`.
- You have local testing ready with `docker compose up -d` (no AWS account required to test locally!).
- When Rice University is ready to take ownership, you hand them `docs/TRANSFER_GUIDE.md`.
