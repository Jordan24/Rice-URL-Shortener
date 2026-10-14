---
name: docker
description: Containerization patterns, multi-stage builds, Docker Compose orchestration, security hardening, and production optimization for Dart/Serverpod backends.
---

# Docker Containerization Skill Guide

Docker packages software into standardized units for development, shipping, and deployment.

## 1. Multi-Stage Builds for Dart / Serverpod
Dart applications should always use multi-stage Docker builds to minimize attack surface and image size:
1. **Stage 1 (Builder)**: `FROM dart:stable AS build`
   - Installs dependencies (`dart pub get`).
   - Compiles native Ahead-Of-Time (AOT) machine binary (`dart compile exe bin/main.dart -o bin/server`).
2. **Stage 2 (Runtime)**: `FROM debian:bookworm-slim`
   - Does NOT include the Dart compiler or SDK.
   - Copies only the compiled binary and required configuration/asset files.
   - Creates a non-root system user (`USER appuser`).
   - Image size drops from ~1.2 GB to ~65 MB.

## 2. Docker Compose for Local Orchestration
Local development requires multiple interacting services:
- **Serverpod Backend**: The Dart API and redirect engine.
- **PostgreSQL**: Relational database storage on port 5432.
- **Redis**: In-memory cache and pub/sub message broker on port 6379.

Using `docker-compose.yml`, dependencies and health checks ensure proper startup order (e.g. Serverpod waits for PostgreSQL `pg_isready` before launching).

## 3. Container Security Hardening
- **Run as Non-Root**: Never run containers as UID 0 (`root`) in production.
- **Read-Only Root Filesystem**: Mount scratch or upload directories to `/tmp` as tmpfs.
- **Health Checks**: Include a `HEALTHCHECK` instruction to notify Docker and ECS of container health.

