# Mars Pathfinder — Production Architecture Specification

**System**: Mars Pathfinder Planetary Exploration & Mission Planning Platform  
**Target Environment**: Linux Containers (Docker / Kubernetes)  
**Security Standard**: Least Privilege, Non-Root Containers, Isolated Network  
**Date**: November 2026  

---

## 1. Architectural Principles

1. **Go Fiber as Single Public Gateway**:
   - The Go Fiber v3 backend ([`backend/cmd/api/main.go`](file:///c:/mars-pathfinder/backend/cmd/api/main.go)) is the only authoritative public REST API gateway on port `8081`.
   - The Python scientific engine operates solely as an internal computing worker via standard subprocess IPC ([`backend/internal/worker/worker.go`](file:///c:/mars-pathfinder/backend/internal/worker/worker.go)), never as an independently exposed public network service.
2. **Deterministic Data Provenance**:
   - Numerical calculations (Horn slope, elevation relief, atmospheric density, diurnal thermal regimes) are derived directly from authentic PDS3 MOLA MEGDR binary rasters and verified GCM physics.
   - Observation status strictly differentiates directly observed laser altimeter cells (`Measured (N shots)`) from 2D spline interpolation (`Interpolated Surface`).
3. **Transparent Persistence Boundaries**:
   - The platform strictly distinguishes relational PostgreSQL/PostGIS storage from local persistent file caching. If database connectivity is unavailable, the application provides an atomic local file fallback with transparent warnings.

---

## 2. Component Architecture & Data Flow

```mermaid
flowchart TD
    subgraph Edge ["Edge / Client Layer"]
        Browser["Modern Web Browser (CesiumJS WebGL + OpenLayers Canvas)"]
    end

    subgraph ContainerProxy ["Frontend Container (Port 8088 / 80)"]
        Nginx["Nginx Reverse Proxy & Static Host"]
    end

    subgraph ContainerAPI ["Backend Container (Port 8081)"]
        Fiber["Go Fiber v3 REST API Engine"]
        WorkerIPC["worker.go Subprocess IPC Manager"]
        PythonEngine["Python 3.12 Scientific Computing Core"]
        MOLABuffer["MOLA MEGDR 4 ppd Binary Raster in RAM"]
    end

    subgraph ContainerDB ["Database Container (Port 5434 / 5432)"]
        Postgres["PostgreSQL 17 Relational Engine"]
        PostGIS["PostGIS 3.5 Spatial Extension (ESRI:104905)"]
        MissionsTable[("Table: mars_missions")]
    end

    Browser -->|HTTP/HTTPS Port 8088| Nginx
    Nginx -->|Static React Bundle| Browser
    Nginx -->|Reverse Proxy /api/ & /health| Fiber
    Fiber -->|Connection Pool (TCP 5432)| Postgres
    Postgres --> PostGIS
    PostGIS --> MissionsTable
    Fiber -->|JSON Subprocess IPC| WorkerIPC
    WorkerIPC --> PythonEngine
    PythonEngine --> MOLABuffer
```

---

## 3. Production Security Hardening

### 3.1. Non-Root Container Execution
The production backend container drops root privileges immediately after system package installation:
```dockerfile
RUN groupadd -r mars && useradd -r -g mars -d /app -s /bin/bash mars
USER mars
```
All application files, datasets, and execution binaries are owned by `mars:mars`.

### 3.2. Cross-Origin Resource Sharing (CORS) Policy
In production, CORS is restricted to verified origins:
```go
app.Use(cors.New(cors.Config{
    AllowOrigins: []string{
        "http://localhost:8088",
        "http://127.0.0.1:8088",
        "http://localhost:5180",
    },
    AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
}))
```

### 3.3. SQL Injection Prevention & Query Safety
All database interactions use parameterized queries via `jackc/pgx/v5`:
```go
db.Exec(`
    INSERT INTO mars_missions (id, name, rover_type, routing_mode, created_at, plan)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (id) DO UPDATE SET name=$2, rover_type=$3, routing_mode=$4, plan=$6
`, id, req.Name, req.RoverType, req.RoutingMode, record.CreatedAt, planJSON)
```

### 3.4. Secrets & Credential Management
- No passwords, tokens, or private secrets are committed to version control.
- Passwords are provided at runtime via environment variables (`${DB_PASSWORD}`) or container secrets.

### 3.5. Internal Container Health Probes
The backend container incorporates a native health probe running under the unprivileged `mars` user:
```dockerfile
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1
```
- Operates directly inside the container network namespace using `curl` against the Go Fiber `/health` endpoint.
- Avoids external dependencies or third-party wrappers.
- The `mars` user retains execution permissions over binaries and read-only access to PDS3 datasets (`data/`).

### 3.6. Network Boundary & Minimal Port Exposure
- **Public Ingress**: Port `8088` (Nginx) is the sole public HTTP entry point for web clients.
- **Backend API**: Port `8081` is accessible internally across the Docker network bridge (`mars-pathfinder_default`).
- **Database Engine**: PostgreSQL port `5434` is bound strictly to `127.0.0.1` (localhost loopback) on the host to prevent unauthorized remote network exposure while permitting administrative diagnostics.

---

## 4. Platform Runtimes & Execution Modes

| Environment | Primary API Runtime | Scientific Processing | Storage Mode |
|:---|:---|:---|:---|
| **Production (Docker Compose)** | Go Fiber v3 statically linked binary (`mars-api`) | Subprocess IPC to Python 3.12 runner | PostgreSQL 17 + PostGIS 3.5 container with persistent volume |
| **Production (Kubernetes)** | Go Fiber v3 container pod | Container sidecar or embedded Python runtime | Managed PostgreSQL (Cloud SQL / Amazon RDS for PostgreSQL) |
| **Local Development (Windows 11)** | Python 3.12 development adapter (`server.py`) | Direct in-process invocation | Local persistent JSON cache (`data/missions_store.json`) with auto-sync |

---

## 5. Maintained Architecture Links

- **Deployment Guide**: [`docs/DEPLOYMENT_GUIDE.md`](file:///c:/mars-pathfinder/docs/DEPLOYMENT_GUIDE.md)
- **API Specification**: [`docs/API_SPECIFICATION.md`](file:///c:/mars-pathfinder/docs/API_SPECIFICATION.md)
- **Final Test Report**: [`docs/FINAL_TEST_REPORT.md`](file:///c:/mars-pathfinder/docs/FINAL_TEST_REPORT.md)
- **Release Readiness Report**: [`docs/RELEASE_READINESS_REPORT.md`](file:///c:/mars-pathfinder/docs/RELEASE_READINESS_REPORT.md)
