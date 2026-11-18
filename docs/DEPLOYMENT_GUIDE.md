# Mars Pathfinder — Production Deployment & Operations Guide

**System**: Mars Pathfinder Planetary Exploration & Mission Planning Platform  
**Target Environment**: Linux Containers (Docker Compose / Kubernetes) & Windows 11 Development  
**Version**: 1.1.0-production  
**Date**: November 2026  

---

## 1. Production Architecture Overview

The production architecture consists of three orchestrated container services communicating over an isolated Docker network:

```mermaid
flowchart TD
    Client["Client Web Browser / Mission Operations Console"]
    
    subgraph Host ["Production Host (Docker Network: mars_net)"]
        Nginx["Frontend Web Server (Nginx Alpine - Port 8088:80)"]
        Backend["Go Fiber v3 API + Python Worker (Port 8081)"]
        Postgres["PostgreSQL 17 + PostGIS 3.5 Database (Port 5434:5432)"]
        VolumeDB[("Volume: mars_db_data")]
    end

    Client -->|HTTP Port 8088| Nginx
    Nginx -->|Static Assets| Nginx
    Nginx -->|Reverse Proxy /api/ & /health| Backend
    Backend -->|Connection Pool (Port 5432)| Postgres
    Backend -->|Subprocess IPC (Python 3.12)| MOLA["MOLA Binary Rasters & GCM Engines"]
    Postgres --> VolumeDB
```

---

## 2. Production Docker Deployment

### 2.1. Prerequisites & Environment Setup
Create a production `.env` configuration file in the project root:

```bash
# Security Credentials
DB_PASSWORD=replace_with_your_database_password
POSTGRES_DB=mars_pathfinder
POSTGRES_USER=mars_admin

# API & Networking
APP_PORT=8081
FRONTEND_PORT=8088
FRONTEND_ORIGIN=http://localhost:8088

# NASA Remote Sensing Credentials
VITE_CESIUM_ION_TOKEN=your_cesium_ion_token_here
VITE_CESIUM_MARS_ASSET_ID=3644333
VITE_MARS_WMTS_CAPABILITIES_URL=https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml
VITE_MARS_GLOBAL_LAYER_ID=Mars_MGS_MOLA_ClrShade_merge_global_463m
VITE_MARS_MATRIX_SET=default028mm
```

### 2.2. Deployment Commands

1. **Build Container Images**:
   ```bash
   docker compose build --no-cache
   ```

2. **Start Services in Detached Mode**:
   ```bash
   docker compose up -d
   ```

3. **Verify Service Health Status**:
   ```bash
   docker compose ps
   ```
   *Expected Output*: All 3 containers (`mars-pathfinder-db`, `mars-pathfinder-api`, `mars-pathfinder-frontend`) showing state `Up (healthy)`.

4. **Inspect Application Logs**:
   ```bash
   # Follow backend logs
   docker compose logs -f backend

   # Follow database logs
   docker compose logs -f database

   # Follow frontend logs
   docker compose logs -f frontend
   ```

5. **Stop Services**:
   ```bash
   # Graceful shutdown preserving data volumes
   docker compose down

   # Shutdown removing volumes (CAUTION: wipes database)
   docker compose down -v
   ```

---

## 3. Database Management & Persistence

### 3.1. Database Initialization
When `mars-pathfinder-db` starts for the first time, PostgreSQL executes all scripts under `backend/migrations/` in alphanumeric order:
- `001_initial_schema.sql`: Enables PostGIS extension, creates spatial reference systems (`ESRI:104905`), and initializes tables (`mars_regions`, `mars_layers`, `mars_missions`).
- `002_seed_data.sql`: Seeds official NASA landing sites and verified planetary map layers.

### 3.2. Authoritative Database Backup
To perform an authoritative backup of the active PostgreSQL database:
```bash
docker compose exec database pg_dump -U mars_admin -d mars_pathfinder --clean --if-exists > backup_mars_$(date +%Y%m%d_%H%M%S).sql
```

### 3.3. Database Restore & Verification in Isolated Database
To restore and verify backup integrity without overwriting or corrupting the production database:
```bash
# 1. Create a distinct, isolated test database inside PostgreSQL
docker compose exec database psql -U mars_admin -d postgres -c "CREATE DATABASE mars_test;"

# 2. Restore the SQL backup dump into the isolated test database
docker compose exec -T database psql -U mars_admin -d mars_test < backup_mars_20261114_120000.sql

# 3. Verify that table schemas and row counts match the production database
docker compose exec database psql -U mars_admin -d mars_pathfinder -c "SELECT count(*) AS prod_count FROM mars_missions;"
docker compose exec database psql -U mars_admin -d mars_test -c "SELECT count(*) AS test_count FROM mars_missions;"

# 4. Clean up the test database once verification is confirmed
docker compose exec database psql -U mars_admin -d postgres -c "DROP DATABASE mars_test;"
```

### 3.4. Production In-Place Database Restore
To perform an in-place disaster recovery restore of the production database from an authoritative backup:
```bash
docker compose exec -T database psql -U mars_admin -d mars_pathfinder < backup_mars_20261114_120000.sql
```

---

## 4. Operational Readiness & Recovery

### 4.1. Health Check Probes
- **Go API Health Endpoint**: `http://localhost:8081/health`  
  *Response*: `{"status": "healthy", "service": "mars-pathfinder-api", "version": "1.1.0-full-application"}`
- **Database Connection Probe**: `http://localhost:8081/api/v1/health/database`  
  *Response (Connected)*: `{"status": "connected", "database": "mars_pathfinder", "regions_indexed": 8, "layers_available": 5}`  
  *Response (Offline Fallback)*: `{"status": "unavailable", "message": "..."}` with HTTP 503.

### 4.2. Storage Disclosures & Non-Misleading Persistence
The API strictly differentiates database persistence from local storage fallback:
- When PostgreSQL is active, saved missions return:
  ```json
  "storage_type": "database",
  "persisted_to_database": true,
  "storage_notice": "Permanently persisted to PostgreSQL / PostGIS database."
  ```
- When running in offline or fallback mode without PostgreSQL, missions are written to `data/missions_store.json` and return:
  ```json
  "storage_type": "local_storage_fallback",
  "persisted_to_database": false,
  "storage_notice": "Stored in local persistent cache (PostgreSQL database service not configured/running)."
  ```

---

## 5. Rollback Procedures

If a critical defect is discovered in production:
1. Revert Git tag to previous stable release:
   ```bash
   git checkout tags/v1.0.0-stable
   ```
2. Rebuild and restart containers:
   ```bash
   docker compose down
   docker compose up -d --build
   ```
3. Restore database snapshot if migrations were applied:
   ```bash
   docker compose exec -T database psql -U mars_admin -d mars_pathfinder < pre_migration_backup.sql
   ```
