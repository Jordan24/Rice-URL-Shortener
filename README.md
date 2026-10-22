# Rice University URL Shortener & QR Studio

An institutional-grade, privacy-respecting URL shortening and branded dynamic QR code generation platform designed for **Rice University**.

Built with a modern web architecture:
- **Frontend**: Flutter Web (responsive desktop/tablet/mobile, institutional Rice design system).
- **Backend**: Containerized Serverpod (Dart) service running on AWS.
- **Database**: PostgreSQL (relational storage with ACID guarantees and high-performance indexed lookups).
- **Infrastructure as Code**: Terraform automated AWS provisioning (ECS Fargate, RDS PostgreSQL, ALB, Route 53, ACM SSL, CloudFront/S3).
- **Ownership & Portability**: Designed from the ground up for seamless handoff to Rice University Office of Information Technology (OIT), transitioning from `go.thejambers.com` to `rice.edu`.

---

## Architecture Overview

```
                                +-----------------------------+
                                |      Browser / User         |
                                +--------------+--------------+
                                               |
                                               v (Unified Domain: go.thejambers.com)
                                +-----------------------------+
                                |    AWS CloudFront CDN       |
                                +--------------+--------------+
                                               |
                      +------------------------+------------------------+
                      | (/ , /assets/*, static assets, SPA routes)      | (/* short links, /api/*, /health)
                      v                                                 v
         +--------------------------+                      +--------------------------+
         |     Amazon S3 Bucket     |                      |  Application Load        |
         |    (Flutter Web SPA)     |                      |  Balancer (ALB / ECS)    |
         +--------------------------+                      +-------------+------------+
                                                                         |
                                                                         v
                                                      +-------------------------------------+
                                                      |     Serverpod Backend Container     |
                                                      |     (AWS ECS Fargate Tasks)         |
                                                      +------------------+------------------+
                                                         |
                                        +----------------+----------------+
                                        |                                 |
                                        v                                 v
                         +-----------------------------+   +-----------------------------+
                         |       RDS PostgreSQL        |   |         Redis Cache         |
                         |   (Short links, Analytics)  |   |   (Rate limits, Session)    |
                         +-----------------------------+   +-----------------------------+
```

---

## Learning Modules: Terraform & Docker

### 1. Understanding Terraform (Infrastructure as Code)
**What is Terraform?**
Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp. Instead of manually clicking buttons in the AWS Management Console to create virtual private clouds (VPCs), databases, and load balancers, you declare the desired end state in declarative `.tf` configuration files.

**Why use Terraform for this project?**
1. **Reproducibility & Handoff**: When Rice University takes over ownership, Rice OIT does not need manual migration checklists. They simply run `terraform apply` with their AWS credentials, and an identical, isolated production environment is created in their AWS account in under 10 minutes.
2. **Version Control**: Every infrastructure change (security groups, compute size, database backups) is tracked in Git alongside the application code.
3. **Safety via `plan`**: Terraform calculates the difference between current state and desired state before touching real cloud resources.

**Key Terraform Workflow Steps**:
- `terraform init`: Downloads the required cloud provider plugins (e.g., `hashicorp/aws`).
- `terraform plan`: Inspects your AWS environment and computes the exact changes (creates, updates, destroys) without applying them.
- `terraform apply`: Provisions the infrastructure in AWS according to the approved plan.
- `terraform destroy`: Safely removes all provisioned cloud resources when no longer needed.

> 📖 **Deep Dive**: Read [`docs/TERRAFORM_GUIDE.md`](docs/TERRAFORM_GUIDE.md) for a line-by-line breakdown of every AWS resource configured in `terraform/`.

---

### 2. Understanding Docker (Containerization)
**What is Docker?**
Docker packages an application and all its dependencies (runtime, system libraries, configuration) into a self-contained unit called an **image**. When that image runs, it executes inside an isolated environment called a **container**.

**Why use Docker for Serverpod?**
1. **No "It Works On My Machine"**: Dart compilation, system libraries, and configuration are identical whether running on macOS, Linux, AWS ECS, or Rice University's internal servers.
2. **Multi-Stage Build Optimization**: Our `server/Dockerfile` uses a two-stage build:
   - **Build Stage**: Uses the full `dart:stable` SDK to compile Dart source code into a native AOT binary.
   - **Runtime Stage**: Copies *only* the compiled binary into a minimal `debian:bookworm-slim` base image, reducing image size from >1 GB down to ~65 MB and eliminating compiler attack surfaces.
3. **Local Full-Stack Testing**: With `docker-compose.yml`, you can spin up the Serverpod server, PostgreSQL database, and Redis cache with a single command: `docker compose up`.

> 📖 **Deep Dive**: Read [`docs/DOCKER_GUIDE.md`](docs/DOCKER_GUIDE.md) for container lifecycle, optimization techniques, and multi-stage build mechanics.

---

## Quickstart: Running Locally

### Prerequisites
- [Docker & Docker Compose](https://docs.docker.com/get-docker/) installed.
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version >= 3.22).
- [Terraform CLI](https://developer.hashicorp.com/terraform/install) (version >= 1.5.0).

### 1. Start the Backend with Docker Compose
Clone the repository and launch the containerized backend, PostgreSQL, and Redis:
```bash
# Start PostgreSQL, Redis, and Serverpod backend
docker compose up -d

# Check running services
docker compose ps

# View backend logs
docker compose logs -f server
```
The Serverpod backend will be available at:
- **API & Endpoints**: `http://localhost:8080`
- **Web Redirect Handler**: `http://localhost:8081`

### 2. Run the Flutter Web Frontend
```bash
# Get dependencies
flutter pub get

# Run all unit and widget tests
flutter test

# Start local web development server
flutter run -d chrome
```

---

## AWS Deployment Guide (Personal Testing & Staging)

If you do not yet have an AWS account, follow our step-by-step onboarding guide:
1. Review [`docs/AWS_SETUP_GUIDE.md`](docs/AWS_SETUP_GUIDE.md) to create your AWS account, configure an IAM user, and install the AWS CLI.
2. Navigate to `terraform/`:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your AWS region and domain (`go.thejambers.com`).
4. Execute Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

---

## Institutional Handoff to Rice University

To hand off this project to Rice University Office of Information Technology (OIT):
1. Send them [`docs/TRANSFER_GUIDE.md`](docs/TRANSFER_GUIDE.md).
2. The transfer guide walks Rice OIT engineers through:
   - Creating or designating a Rice AWS account.
   - Applying `terraform/` configured with `domain_name = "rice.edu"` (e.g. `link.rice.edu`).
   - Integrating Rice NetID Single Sign-On (SAML 2.0 / Shibboleth / OIDC) into the authentication adapter.
   - Migrating DNS records and activating Rice institutional SSL certificates.

---

## Project Structure

```
├── AGENTS.md                  # Comprehensive AI agent instructions and project guidelines
├── README.md                  # This documentation
├── docker-compose.yml         # Local orchestration (PostgreSQL + Redis + Serverpod)
├── lib/                       # Flutter Web frontend
│   ├── core/                  # Constants (Rice colors, logos), theme, utils, QR drawing
│   ├── data/                  # ShortLink model, AuthService (AWS Cognito), Serverpod link service
│   └── presentation/          # Views (Auth, Dashboard, 404), State controllers, Modal widgets
├── server/                    # Serverpod Dart backend
│   ├── bin/                   # Entry point (main.dart)
│   ├── config/                # Environment configurations (development, production)
│   ├── lib/src/               # Endpoints, protocol models, web redirect routes
│   ├── migrations/            # SQL migration scripts for PostgreSQL
│   └── Dockerfile             # Multi-stage container build definition
├── client/                    # Generated/structured Serverpod client library
├── terraform/                 # Infrastructure as Code for AWS
│   ├── main.tf                # VPC, subnets, route tables, security groups
│   ├── rds.tf                 # PostgreSQL RDS database instance
│   ├── ecs.tf                 # ECS Fargate cluster, task definition, and service
│   ├── alb.tf                 # Application Load Balancer and target groups
│   ├── route53_acm.tf         # Route 53 DNS and ACM SSL certificate
│   ├── s3_frontend.tf         # S3 static hosting + CloudFront CDN for Flutter Web
│   ├── variables.tf           # Parameter declarations
│   ├── outputs.tf             # Outputs (endpoints, URLs, nameservers)
│   └── terraform.tfvars.example
├── docs/                      # Institutional guides & tutorials
│   ├── TRANSFER_GUIDE.md      # Rice University OIT Handoff & Migration Manual
│   ├── TERRAFORM_GUIDE.md     # Step-by-step Terraform learning tutorial
│   ├── DOCKER_GUIDE.md        # Containerization & Docker learning tutorial
│   └── AWS_SETUP_GUIDE.md     # AWS account creation & CLI guide
├── test/                      # Frontend unit and widget tests
└── web/                       # Web index.html, CNAME, manifest, and icons
```

---

## License & Copyright
Developed for Rice University. Rice marks and crests are copyright Rice University.
