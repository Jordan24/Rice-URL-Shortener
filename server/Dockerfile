# =============================================================================
# STAGE 1: Build & Compile the Serverpod Dart Binary
# =============================================================================
FROM dart:stable AS build

WORKDIR /app

# Copy source trees
COPY server/ /app/server/
COPY client/ /app/client/

# Clean host-specific .dart_tool and build directories so container resolves fresh in Linux
RUN rm -rf /app/server/.dart_tool /app/client/.dart_tool /app/server/build /app/client/build

WORKDIR /app/server
RUN dart pub get

# Compile native AOT binary
RUN dart compile exe bin/main.dart -o bin/server

# =============================================================================
# STAGE 2: Lightweight Production Runtime
# =============================================================================
FROM debian:bookworm-slim

# Install runtime dependencies (certificates for HTTPS requests & curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Security hardening: Create non-root system user
RUN groupadd -r riceuser && useradd -r -g riceuser -m -d /home/riceuser riceuser

WORKDIR /app

# Copy compiled binary and configuration
COPY --from=build --chown=riceuser:riceuser /app/server/bin/server /app/bin/server
COPY --from=build --chown=riceuser:riceuser /app/server/config/ /app/config/
COPY --from=build --chown=riceuser:riceuser /app/server/migrations/ /app/migrations/

USER riceuser

# Serverpod ports: 8080 (API), 8081 (Web Server & Redirection), 8082 (Insights)
EXPOSE 8080 8081 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

ENTRYPOINT ["/app/bin/server"]
CMD ["--mode", "production"]

