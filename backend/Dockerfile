# ==============================================================================
# Mars Pathfinder — Production Backend Dockerfile
# Multi-stage build: Go Fiber v3 API + Python 3.12 Scientific Processing Runtime
# ==============================================================================

# Stage 1: Build the Go Fiber v3 binary
FROM golang:1.24-bookworm AS builder
WORKDIR /app

# Cache dependencies
COPY backend/go.mod backend/go.sum* ./
RUN go mod download

# Build statically linked binary
COPY backend/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o mars-api ./cmd/api

# Stage 2: Production Runtime with Python 3 and Scientific Libraries
FROM python:3.12-slim-bookworm AS runner

# Create non-root system user
RUN groupadd -r mars && useradd -r -g mars -d /app -s /bin/bash mars

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python scientific packages
COPY processing/requirements.txt ./processing/requirements.txt
RUN pip install --no-cache-dir -r ./processing/requirements.txt

# Copy Go binary, scientific modules, and authentic datasets
COPY --from=builder /app/mars-api /app/mars-api
COPY processing/ /app/processing/
COPY data/ /app/data/

# Environment variables
ENV APP_ENV=production \
    APP_PORT=8081 \
    PYTHONUNBUFFERED=1 \
    WORKSPACE_ROOT=/app

RUN chown -R mars:mars /app
USER mars

EXPOSE 8081

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

ENTRYPOINT ["/app/mars-api"]
