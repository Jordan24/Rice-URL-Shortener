# Learning Docker: Containerization Guide for Serverpod & Dart

Welcome to Docker! This guide explains **what Docker is, why we use it for the Rice URL Shortener backend, how multi-stage builds work, and how to use Docker Compose for local full-stack development**.

---

## 1. What is Docker and Why Do We Need It?

### The Traditional Dilemma: "Works on My Machine"
In traditional server software deployment:
- You develop on macOS with Dart 3.12 and PostgreSQL 16 installed locally.
- When you deploy to AWS (or when **Rice University** runs it on their internal Linux servers), their server might have a different Dart version, missing C libraries (`libc`, `libssl`), or incompatible environment variables.
- Result: Bugs that only happen on the server and are impossible to reproduce locally.

### The Solution: Containers
A **Docker container** packages the application along with *everything* it needs to run:
- The compiled binary
- System libraries
- Configuration files
- Runtime environment

Whether you run the container on your Mac laptop, in AWS ECS Fargate, or in Rice University's on-premises datacenter, **the container runs exactly the same everywhere**.

### Image vs Container: The Quick Analogy
- **Image**: Like a blueprint or a recipe (e.g. a static snapshot of our Serverpod server). It is read-only.
- **Container**: An actively running instance of that image (like the baked cake). You can run 5 containers from the same image simultaneously.

---

## 2. Deep Dive: Multi-Stage Builds (`server/Dockerfile`)

Our Serverpod backend uses a **Multi-Stage Dockerfile**. This is an industry best practice for compiled languages like Dart, Go, and Rust.

Here is the exact structure of `server/Dockerfile`:

```dockerfile
# ==========================================
# STAGE 1: Build & Compile the Dart Binary
# ==========================================
FROM dart:stable AS build

WORKDIR /app

# 1. Copy dependency files first for layer caching
COPY server/pubspec.* ./server/
COPY client/pubspec.* ./client/

# 2. Download package dependencies
WORKDIR /app/server
RUN dart pub get

# 3. Copy the remaining server source code
COPY server/ /app/server/
COPY client/ /app/client/

# 4. Compile native Ahead-Of-Time (AOT) machine code binary
RUN dart compile exe bin/main.dart -o bin/server

# ==========================================
# STAGE 2: Lightweight Production Runtime
# ==========================================
FROM debian:bookworm-slim

# Install minimal runtime dependencies (ca-certificates for SSL/TLS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root system user for security
RUN groupadd -r riceuser && useradd -r -g riceuser -m -d /home/riceuser riceuser

WORKDIR /app

# Copy ONLY the compiled binary and config from the build stage
COPY --from=build --chown=riceuser:riceuser /app/server/bin/server /app/bin/server
COPY --from=build --chown=riceuser:riceuser /app/server/config/ /app/config/

# Switch to the non-root user
USER riceuser

# Expose Serverpod ports: 8080 (API), 8081 (Web Redirects / Insights)
EXPOSE 8080 8081

# Add container health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

# Launch the compiled server binary
CMD ["/app/bin/server", "--mode", "production"]
```

### Why Multi-Stage Builds are Crucial:
1. **Dramatic Image Size Reduction**:
   - The `dart:stable` SDK image is **~1.2 GB** because it contains the Dart compiler, Dart analyzer, package manager, and Linux build tools.
   - The runtime `debian:bookworm-slim` image with our compiled binary is only **~65 MB**!
   - Smaller images download faster in AWS ECS, start up in seconds, and use less bandwidth.
2. **Security Hardening**:
   - The production container does NOT contain compilers, Git, or source code. If an attacker ever gained access to the container, they cannot compile exploit payloads.
   - The container runs as `riceuser` instead of `root`, preventing container-breakout vulnerabilities.

---

## 3. Docker Compose: Running the Whole Stack Locally

To test the backend locally, Serverpod needs:
1. **Serverpod Server**
2. **PostgreSQL Database**
3. **Redis Cache**

Instead of manually starting 3 separate tools, `docker-compose.yml` orchestrates all three with a single command.

### How `docker-compose.yml` Works:
```yaml
version: '3.8'

services:
  # 1. PostgreSQL Database Service
  postgres:
    image: postgres:16-alpine
    container_name: rice_url_shortener_db
    environment:
      POSTGRES_DB: riceshortener
      POSTGRES_USER: rice_admin
      POSTGRES_PASSWORD: rice_password_dev_1912
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./server/migrations/initial_schema.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rice_admin -d riceshortener"]
      interval: 5s
      timeout: 5s
      retries: 5

  # 2. Redis In-Memory Cache
  redis:
    image: redis:7-alpine
    container_name: rice_url_shortener_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # 3. Serverpod Backend Service
  server:
    build:
      context: .
      dockerfile: server/Dockerfile
    container_name: rice_url_shortener_server
    ports:
      - "8080:8080" # API & RPC Endpoint
      - "8081:8081" # Web Redirection & Health Checks
    environment:
      - SERVERPOD_DATABASE_HOST=postgres
      - SERVERPOD_DATABASE_PORT=5432
      - SERVERPOD_DATABASE_NAME=riceshortener
      - SERVERPOD_DATABASE_USER=rice_admin
      - SERVERPOD_DATABASE_PASSWORD=rice_password_dev_1912
      - SERVERPOD_REDIS_HOST=redis
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started

volumes:
  postgres_data:
  redis_data:
```

### Key Highlights:
- **`depends_on` with `service_healthy`**: The backend waits for PostgreSQL to pass its health check before starting, preventing crash loops on boot.
- **Persistent Volumes (`volumes:`)**: Your test shortened links are saved in `postgres_data`, so stopping the containers does NOT delete your test data!

---

## 4. Essential Docker Commands Cheat Sheet

### Starting the Stack
```bash
# Start all containers in the background (detached mode)
docker compose up -d

# Build images and start
docker compose up -d --build
```

### Inspecting Running Containers
```bash
# View running containers and their status
docker compose ps

# View live stream of server logs
docker compose logs -f server

# View database logs
docker compose logs -f postgres
```

### Stopping the Stack
```bash
# Stop containers without deleting saved database data
docker compose stop

# Stop containers and remove network
docker compose down

# Stop containers and delete all database volumes (fresh start)
docker compose down -v
```

### Inspecting Inside a Container
```bash
# Open an interactive shell inside the server container
docker compose exec server bash

# Open a PostgreSQL command-line inside the database container
docker compose exec postgres psql -U rice_admin -d riceshortener
```

---

## 5. How Rice University Runs This Container

Rice University can deploy this Docker container anywhere:
- **AWS ECS Fargate**: Serverless containers managed by AWS (default in our Terraform code).
- **AWS App Runner**: Fully managed container runner.
- **Rice Kubernetes Cluster (EKS or on-prem)**: Simply write a standard Kubernetes `Deployment` and `Service` manifest referencing the ECR image.
- **Standalone Docker Host (EC2 / VM)**: Run `docker compose up -d` on an institutional Linux VM.

