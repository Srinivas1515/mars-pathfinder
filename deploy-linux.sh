#!/usr/bin/env bash
# ==============================================================================
# Mars Pathfinder — Production Linux VPS Deployment Script
# Target: Ubuntu 22.04/24.04 LTS or Debian 12 with Docker & Docker Compose
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " Mars Pathfinder — Production Linux VPS Deployment"
echo "=========================================================="

# 1. Check Docker Engine installation
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker Engine is not installed on this host."
    echo "Install Docker using official repository instructions:"
    echo "  curl -fsSL https://get.docker.com | sh"
    echo "  sudo usermod -aG docker \$USER"
    exit 1
fi

# 2. Check Docker Compose CLI
if docker compose version &> /dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
else
    echo "[ERROR] Docker Compose plugin or binary not found."
    echo "Install Compose via: sudo apt-get install docker-compose-plugin"
    exit 1
fi

echo "[INFO] Using Compose: $($COMPOSE version)"

# 3. Environment configuration check
if [ ! -f .env ]; then
    echo "[ERROR] Production .env file is missing."
    echo "Copy .env.example to .env and configure secure values."
    exit 1
fi

echo "[INFO] Production environment file found."

# 4. Validate Compose configuration
echo "[1/4] Validating Docker Compose configuration..."
$COMPOSE config > /dev/null
echo "  [PASS] Docker Compose syntax and dependencies valid."

# 5. Build Container Images
echo "[2/4] Building production images (Go API + Python worker, React + Nginx)..."
$COMPOSE build

# 6. Start Services
echo "[3/4] Launching microservices..."
$COMPOSE up -d

# 7. Health Probe
echo "[4/4] Verifying container health..."
sleep 5
$COMPOSE ps

echo "=========================================================="
echo " Mars Pathfinder Deployment Complete!"
echo " Web Application / Reverse Proxy: http://localhost:8088"
echo " Authoritative Go API Health:     http://localhost:8088/health"
echo " PostgreSQL PostGIS Database:     127.0.0.1:5434 (Internal: 5432)"
echo "=========================================================="
