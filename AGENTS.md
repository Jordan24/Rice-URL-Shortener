# PROJECT CONTEXT: RICE UNIVERSITY URL SHORTENER & QR STUDIO

## 1. SPECS & ENV
- **Type**: Web-only app (Flutter Web, Dart) + Serverpod Dart Backend in Docker + AWS Infrastructure (Terraform).
- **Domains**: 
  - Development & Testing: `go.thejambers.com` (Unified CloudFront CDN fronting S3 & ECS Serverpod ALB).
  - Target Institutional Domain: Rice University `rice.edu` (e.g., `link.rice.edu` or `go.rice.edu`).
- **Target Platform**: Modern web browsers (Desktop/Tablet/Mobile responsive).
- **Tooling Versions**:
  - Flutter / Dart SDK: Latest stable (Dart 3.x / Flutter 3.x).
  - Backend: Serverpod 2.x (Dart backend framework).
  - Containerization: Docker (multi-stage build with minimal Debian runtime).
  - Infrastructure as Code: Terraform >= 1.5.0 with AWS Provider >= 5.0.
  - GitHub Actions: Keep pinned actions (e.g., `actions/checkout@v6`).

## 2. AUTHENTICATION & INSTITUTIONAL SSO
- **Current Mode**: AWS Cognito User Pool with strict client-side and server-side (`PreSignUp` Lambda trigger) restriction to `@rice.edu` email domains (non-Rice accounts rejected with feedback).
- **Institutional Target**: Rice University Single Sign-On (SSO) via SAML 2.0, Shibboleth, or OpenID Connect (OIDC) tied to Rice NetID / OIT Identity Provider (IdP) federated with AWS Cognito.
- **Architecture**: Auth service abstraction (`AuthService`) decoupling UI from auth provider, allowing plug-and-play migration to Rice NetID SSO.

## 3. LINK SHORTENING & REDIRECTION
- **Shortcode**: Default 5-char alphanumeric (case-insensitive base36/base62 lowercase-normalized).
- **Custom Alias**: URL-safe strings (alphanumeric + hyphens). Check collisions & reserved paths (`app`, `api`, `login`, `static`, `r`, `dashboard`, `health`, `metrics`).
- **Expiration**: Optional timestamp.
- **Fallback**: Default `https://rice.edu` (user customizable).
- **Redirection Engine**: 
  - High-performance HTTP redirect route (`/:code`) in Serverpod container.
  - Returns instant HTTP 301 (Permanent Redirect) for active valid links to preserve SEO and speed.
  - Returns HTTP 302 (Found / Temporary Redirect) for expired or inactive links pointing to fallback URL.
  - Atomically increments click count and records last clicked timestamp in PostgreSQL.
  - REST API & Web Routes: Serverpod Web Server on port 8081 handles `/health` (ALB healthchecks), `/api/*` (Link & Analytics CRUD with full CORS & OPTIONS preflight support), and `/*` (fast HTTP 301/302 redirects).

## 4. QR CODE ENGINE
- **Module Shapes**: 3 styles (`square`, `rounded`, `dots`).
- **Colors**:
  - Presets:
    - Foreground: Rice Blue (`#00205B`), Rice Gray (`#7C7E7F`), Dark Blue (`#00143D`), Light Blue (`#4B729F`), Laurel Gold (`#C19B4C`), Black (`#000000`).
    - Background (Light Brand Tones): White (`#FFFFFF`), Off-White (`#F7F7F7`), Light Gray (`#E0E2E6`), Light Blue Gray (`#ADC7DC`), Accent Light Blue (`#CFEEFC`), Transparent (`#00000000`).
  - Custom Color Picker (Hex/RGB). Default: Rice Blue foreground, White background.
- **Center Logos**: Official Rice marks with quiet zone cutout:
  1. `shield` (Rice University Crest / Shield - Academic)
  2. `owl` (Rice Owl - Spirit/Athletics)
  3. `old_english_r` (Old English R)
  4. `none`
  - Default: First option (`shield`).
- **Exports**: Web client-side Canvas/SVG rasterizer for PNG (512px, 1024px, 2048px) and scalable SVG.

## 5. UI/UX & DESIGN SYSTEM (RICE.EDU INSPIRED)
- **Aesthetic**: Institutional elegance of `rice.edu`.
- **Typography**:
  - Headings/Display: `Cormorant Garamond` (Google Font alternate for Copernicus).
  - Body/UI: `Lato` (Google Font alternate for Mallory).
- **Layout**: Top Rice Blue banner with logo/wordmark, user profile menu, crisp card surfaces, high-contrast accessible elements.
- **Dashboard Features**: Full CRUD (Create, Edit destination/fallback/expiration/QR, Toggle Active/Inactive, Delete), Search/Filter, Quick Copy, QR Download modal.

## 6. CODE ARCHITECTURE & QUALITY STANDARDS
- **SRP & DRY**: Every file <150-200 lines. Single dedicated responsibility.
- **Directory Structure**:
  - `lib/core/` (constants, theme, utils, web downloads)
  - `lib/data/` (models, services: auth, link_service interface, serverpod adapter, qr export)
  - `lib/presentation/` (state controllers, widgets: common, qr, links, views: auth, dashboard, 404)
  - `server/` (Serverpod Dart backend: models, endpoints, web redirect routes, config)
  - `client/` (Serverpod client library for Dart/Flutter)
  - `terraform/` (Infrastructure as Code for AWS: VPC, ECS Fargate, RDS PostgreSQL, ALB, Route53, ACM, S3/CloudFront, Cognito)
  - `docs/` (Transfer guide, Terraform tutorial, Docker guide, AWS setup guide)
  - `web/` (index.html, manifest, assets, CNAME)
- **Routing**: Flutter Web HTML5 path URL strategy (no `#` hash routing).

## 7. DATA SCHEMAS
### Serverpod / PostgreSQL Relational Schema:
```sql
-- Table: short_link
CREATE TABLE short_link (
    id SERIAL PRIMARY KEY,
    link_id VARCHAR(64) UNIQUE NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    short_code VARCHAR(64) UNIQUE NOT NULL,
    destination_url TEXT NOT NULL,
    fallback_url TEXT DEFAULT 'https://rice.edu',
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    click_count BIGINT NOT NULL DEFAULT 0,
    last_clicked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    qr_config JSONB
);

CREATE INDEX idx_short_link_code ON short_link (short_code);
CREATE INDEX idx_short_link_user ON short_link (user_id);
```

## 8. INSTITUTIONAL HANDOFF & RICE OWNERSHIP
- Complete transfer documentation is maintained in `docs/TRANSFER_GUIDE.md`.
- Infrastructure is fully automated using Terraform: Rice OIT can provision a dedicated, isolated AWS environment in minutes by applying `terraform/` with their own AWS account credentials and Rice Route53 zones.
- Backend container is portable: Docker image can run on AWS ECS Fargate, AWS App Runner, or on-premises Rice servers.

<!-- BEGIN AWS Agent Toolkit rules -->
# AWS Guidance

Where these AWS rules conflict with the project's own instructions, the project's instructions take precedence.

- Prefer the AWS MCP Server for AWS interactions — it provides sandboxed execution, observability, and audit logging. If unavailable, use the AWS CLI directly.
- Before starting a task, check whether a relevant AWS skill is available. Load the skill with `retrieve_skill` and prefer its guidance over general knowledge.
- When uncertain about specific AWS details (API parameters, permissions, limits, error codes), verify against documentation rather than guessing. State uncertainty explicitly if you cannot confirm.
- When creating infrastructure, prefer infrastructure-as-code (AWS CDK or CloudFormation) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework principles.
- Do not use em dashes in AWS resource names or descriptions. Use hyphens instead.

Secret Safety:
- MUST load the aws-secrets-manager skill first for any secret, credential, API key, token, or password task.
- MUST NOT call secretsmanager get-secret-value or batch-get-secret-value, and MUST NOT hit the Secrets Manager Agent daemon directly.
- MUST use {{resolve:secretsmanager:secret-id:SecretString:json-key}} with asm-exec so the secret resolves at runtime without entering context.
<!-- END AWS Agent Toolkit rules -->
