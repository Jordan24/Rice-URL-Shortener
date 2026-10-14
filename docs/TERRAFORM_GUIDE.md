# Learning Terraform: The Complete Guide & Architecture Walkthrough

Welcome to Terraform! This guide teaches you **what Terraform is, why we use it, how it works, and provides a line-by-line explanation of every component** configured in this project.

---

## 1. What is Terraform and Why Do We Use It?

### The Problem: "ClickOps" (Manual Cloud Management)
When building an application on AWS without Terraform, you typically log into the AWS Management Console and manually click around:
1. Create a VPC.
2. Create 4 subnets across 2 availability zones.
3. Create an Internet Gateway and Route Tables.
4. Create a PostgreSQL RDS instance and configure security groups.
5. Create an ECS Fargate cluster, task definition, and service.
6. Create an Application Load Balancer and target groups.
7. Request an SSL certificate in ACM and create DNS records in Route 53.

**Why this breaks down**:
- **Human Error**: One misconfigured checkbox or security group rule can cause hours of debugging or a security vulnerability.
- **Not Reproducible**: When you want to hand this project to **Rice University**, you cannot tell their OIT team to "follow these 87 manual console steps." They would likely make mistakes.
- **No History or Rollbacks**: You cannot see who changed a firewall rule last week or easily revert it.

### The Solution: Infrastructure as Code (IaC)
With Terraform, you describe your entire infrastructure in human-readable code (`.tf` files) using HashiCorp Configuration Language (HCL).
- **Declarative**: You tell Terraform *what* you want the end state to look like, not *how* to build it. Terraform figures out the dependency graph and the correct order of API calls.
- **1-Click Deployment for Rice University**: Rice OIT can type `terraform apply`, and AWS creates the exact same production-grade infrastructure in their account.
- **Version Control**: Every infrastructure modification is committed to Git, reviewed in pull requests, and tested.

---

## 2. Core Terraform Concepts

### A. Providers
A **provider** is a plugin that Terraform uses to communicate with an API. In our case, the `aws` provider translates Terraform code into AWS API calls (e.g., `ec2:CreateVpc`, `rds:CreateDBInstance`).

### B. State (`terraform.tfstate`)
Terraform keeps track of the real-world resources it created in a JSON file called **state**:
- When you run `terraform plan`, Terraform compares your `.tf` code against the state file and the real AWS cloud.
- If your code says you want 2 ECS tasks, but AWS currently has 1, Terraform plans to add 1.
- In production, state is stored in an S3 bucket with DynamoDB table locking so team members don't overwrite each other.

### C. Resources & Data Sources
- **Resource (`resource "aws_vpc" "main" { ... }`)**: Creates and manages an infrastructure component.
- **Data Source (`data "aws_availability_zones" "available" { ... }`)**: Queries existing information from AWS without creating it (e.g., finding the available data centers in `us-east-1`).

### D. Input Variables & Outputs
- **Variables (`variable "domain_name" { ... }`)**: Parameters you can customize per environment (e.g. `go.thejambers.com` for testing vs `go.rice.edu` for Rice).
- **Outputs (`output "alb_dns_name" { ... }`)**: Values printed after `terraform apply` (e.g. the load balancer URL or database endpoint).

---

## 3. Walkthrough of Our Project's Terraform Files

Let's inspect how each file in `terraform/` works:

### 1. `versions.tf`
Specifies which versions of Terraform and providers are required:
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```
*Why*: Ensures compatibility and prevents unexpected breaking changes from new provider updates.

---

### 2. `variables.tf` & `terraform.tfvars`
Declares all customizable options:
- `aws_region`: Defaults to `us-east-1` (Northern Virginia).
- `domain_name`: Defaults to `go.thejambers.com`.
- `db_username` & `db_password`: Database credentials passed securely.
- `backend_count`: Number of running Serverpod container instances.

---

### 3. `main.tf` (Networking & VPC)
AWS requires your resources to live in a Virtual Private Cloud (VPC):
- **VPC (`10.0.0.0/16`)**: An isolated virtual network in AWS.
- **Public Subnets**: Connected directly to the internet via an **Internet Gateway**. This is where our Application Load Balancer lives to receive web traffic from users.
- **Private Subnets**: Have no direct route to the public internet. This is where our **PostgreSQL database** lives. Hackers cannot reach it directly from the internet!

---

### 4. `rds.tf` (PostgreSQL Database)
Provisions an AWS RDS PostgreSQL 16 database:
```hcl
resource "aws_db_instance" "postgres" {
  engine               = "postgres"
  engine_version      = "16"
  instance_class      = var.db_instance_class
  allocated_storage   = 20
  max_allocated_storage = 100 # Automatically scales up if needed!
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot = true # In production, set to false for safety
}
```
*Why*: RDS provides automated backups, hardware maintenance, replication, and failover without managing Linux servers manually.

---

### 5. `ecs.tf` (Elastic Container Service & Fargate)
Runs our containerized Serverpod backend:
- **Cluster**: Logical grouping of tasks.
- **Fargate Launch Type**: Serverless container execution! AWS manages the underlying servers, operating systems, and security patches. You only pay for the exact vCPU and RAM your container uses.
- **Task Definition**: Specifies the Docker image, environment variables (database connection string), CPU (0.5 vCPU), memory (1 GB), and port mappings (8080/8081).
- **Service**: Keeps the desired number of containers running. If a container crashes, ECS automatically starts a new one.

---

### 6. `alb.tf` (Application Load Balancer)
- Receives traffic from the CloudFront CDN backend origin on HTTP (port 80).
- Forwards requests to the healthy ECS Fargate containers.
- Performs continuous **health checks** (`GET /health`) every 30 seconds. If a container stops responding, the load balancer stops routing users to it.

---

### 7. `route53_acm.tf` (DNS & SSL/TLS Certificates)
- Requests a free, trusted SSL/TLS certificate from **AWS Certificate Manager (ACM)** for your domain.
- Validates domain ownership via DNS CNAME records.
- Creates **A and AAAA Alias** records pointing `go.thejambers.com` (or `go.rice.edu`) directly to the CloudFront Unified CDN with zero latency overhead.

---

### 8. `s3_frontend.tf` (Unified CloudFront CDN & S3 Frontend Hosting)
- Implements the **Option 2 Unified Domain Strategy** (`go.thejambers.com`).
- Stores the compiled Flutter Web frontend in an Amazon S3 bucket.
- Configures **AWS CloudFront** as the single unified entry point:
  - Routes `/` and static assets (`/assets/*`, `/canvaskit/*`, `/icons/*`, `*.js`, `*.wasm`, etc.) to the S3 bucket.
  - Routes `/*` (shortened redirect URLs) and `/api/*` (REST APIs) dynamically to the Serverpod ALB.
- Configures custom 404 error responses so Flutter Web's HTML5 client-side routing works seamlessly when refreshing links.

---

## 4. The 4 Essential Terraform Commands

### Step 1: `terraform init`
```bash
cd terraform
terraform init
```
**What it does**:
- Reads your `.tf` files.
- Downloads the `hashicorp/aws` provider plugin into `.terraform/`.
- Initializes state storage.

### Step 2: `terraform plan`
```bash
terraform plan
```
**What it does**:
- Connects to AWS using your credentials.
- Compares what exists in AWS with what your code specifies.
- Prints a preview of changes:
  - `+` (Green): Resources that will be created.
  - `~` (Yellow): Resources that will be modified.
  - `-` (Red): Resources that will be destroyed.

### Step 3: `terraform apply`
```bash
terraform apply
```
**What it does**:
- Shows the plan again and prompts `Do you want to perform these actions? (yes/no)`.
- When you type `yes`, Terraform calls AWS APIs to create the VPC, RDS, ECS tasks, ALB, and DNS records.
- Takes approximately 5 to 10 minutes (RDS provisioning takes ~4 minutes).

### Step 4: `terraform destroy`
```bash
terraform destroy
```
**What it does**:
- Safely removes all resources created by Terraform, ensuring no ongoing AWS charges when you are finished testing.

---

## 5. Security & Best Practices Checklist
1. **Never commit `terraform.tfstate` or `terraform.tfvars` with secrets to git**: We include them in `.gitignore`.
2. **Least Privilege**: The database only accepts connections from the ECS security group on port 5432. It is completely inaccessible from the outside world.
3. **State Locking**: Use AWS S3 + DynamoDB for team collaboration.

