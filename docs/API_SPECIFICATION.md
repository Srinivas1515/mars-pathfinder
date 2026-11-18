# Mars Pathfinder — REST API Specification v1.1

**Base URL**: `http://localhost:8081`  
**Protocol**: HTTP/1.1  
**Content-Type**: `application/json`  
**CORS Origins**: `http://localhost:5180`, `http://127.0.0.1:5180`, `http://localhost:5173`, `http://localhost:8088`  

---

## 1. Architecture & Authority Statement

### 1.1. Authoritative Production Backend (Go Fiber v3)
- **Specification Source**: Located at [`backend/cmd/api/main.go`](file:///c:/mars-pathfinder/backend/cmd/api/main.go).
- **Runtime**: High-performance Go Fiber v3 HTTP engine on port `8081`.
- **Role**: Serves as the authoritative public REST API for all production deployments, Linux containers, and Docker environments.
- **Worker IPC**: Communicates with the Python scientific processing engine via structured subprocess IPC ([`backend/internal/worker/worker.go`](file:///c:/mars-pathfinder/backend/internal/worker/worker.go)), passing JSON payloads with strict timeout bounds (25s).

### 1.2. Windows 11 Smart App Control (SAC) Development Companion
- **Companion Script**: Located at [`backend/server.py`](file:///c:/mars-pathfinder/backend/server.py).
- **Role**: Provides a 1:1 identical development adapter for local developer machines running Windows 11 with Smart App Control (SAC) or enterprise WDAC code-integrity policies enabled.
- **Why Needed**: On Windows 11 SAC, dynamically compiled, unsigned temporary binaries (`api.exe`) are blocked under Code Integrity Event 3118. Official signed Python 3.12 binaries are permitted.
- **Architectural Harmony**: Both implementations invoke the exact same underlying processing modules in `processing/`, guaranteeing 100% schema, parameter, and response compatibility across environments without divergence.

---

## 2. System Health & Infrastructure

### `GET /health`
Verifies backend service operational state and version.

**Response `200 OK`**:
```json
{
  "status": "healthy",
  "service": "mars-pathfinder-api",
  "version": "1.1.0-full-application"
}
```

### `GET /api/v1/health/database`
Inspects PostgreSQL and PostGIS spatial database connectivity and table indexing.

**Response `200 OK`**:
```json
{
  "status": "connected",
  "database": "mars_pathfinder",
  "regions_indexed": 8,
  "layers_available": 5
}
```

---

## 3. Planetary Gazetteer & Datasets

### `GET /api/v1/regions` (or `/api/v1/mission/presets`)
Retrieves all cataloged Martian geographical exploration regions and landing sites.

**Response `200 OK`**:
```json
[
  {
    "id": "jezero",
    "name": "Jezero Crater",
    "latitude": 18.38,
    "longitude": 77.58,
    "elevation_m": -2530.0,
    "target_type": "Ancient Delta & Crater Lake",
    "description": "Perseverance Rover & Ingenuity landing site; rich in ancient phyllosilicate clay deltas."
  },
  {
    "id": "oxia",
    "name": "Oxia Planum",
    "latitude": 18.27,
    "longitude": -24.63,
    "elevation_m": -3050.0,
    "target_type": "Hydrated Clay Plain",
    "description": "ESA/Roscosmos Rosalind Franklin landing target; widespread Noachian phyllosilicates."
  }
]
```

### `GET /api/v1/layers`
Retrieves all 5 NASA scientific layers with metadata, WMTS endpoints, and radiometric scales.

---

## 4. Module 1 & 2: Surface Elevation & Direct Laser Observation

### `GET /api/v1/elevation/point`
Extracts authentic elevation and observation status from the MOLA MEGDR binary raster and counts array.

**Query Parameters**:
- `lat` (float, required): Latitude in degrees ($[-90.0, 90.0]$).
- `lon` (float, required): Longitude in degrees ($[-180.0, 180.0]$ or $[0.0, 360.0]$).

**Response `200 OK`**:
```json
{
  "latitude": 18.38,
  "longitude": 77.58,
  "elevation_m": -2651.0,
  "observation_status": "observed",
  "observation_count": 510,
  "is_directly_observed": true,
  "vertical_datum": "Martian Areoid (MOLA GMM-2B potential, 610.5 Pa)",
  "projection_datum_radius_m": 3396000.0,
  "product_id": "MEGT90N000CB",
  "counts_product_id": "MEGC90N000CB"
}
```

---

## 5. Module 3: Terrain Analysis & Elevation Profiles

### `GET /api/v1/terrain/analyze`
Applies Horn's (1981) 8-point weighted gradient formula over a $3 \times 3$ grid kernel.

**Query Parameters**:
- `lat` (float, required): Latitude in degrees.
- `lon` (float, required): Longitude in degrees.

**Response `200 OK`**:
```json
{
  "latitude": 18.38,
  "longitude": 77.58,
  "elevation_m": -2651.0,
  "slope_deg": 0.61,
  "aspect_deg": 75.1,
  "aspect_cardinal": "ENE",
  "roughness_rms_m": 200.6,
  "traversability_rating": "Moderate (Acceptable)",
  "recommended_speed_limit_kmh": 0.08,
  "observation_status": "observed",
  "observation_count": 510,
  "is_directly_observed": true
}
```

### `GET /api/v1/terrain/profile`
Computes an elevation and slope profile along a great-circle geodesic between two coordinates.

**Query Parameters**:
- `start_lat`, `start_lon`, `dest_lat`, `dest_lon` (float, required).
- `samples` (int, optional, default: 50, range: 10–200).

---

## 6. Module 4: Environmental & Aerological Modeling

### `GET /api/v1/environmental/point`
Synthesizes physical atmospheric pressure, diurnal thermal swings, dust optical depth, and cosmic radiation dose.

**Query Parameters**:
- `lat` (float, required), `lon` (float, required), `elevation` (float, optional).

**Response `200 OK`**:
```json
{
  "latitude": 18.38,
  "longitude": 77.58,
  "elevation_m": -2651.0,
  "atmospheric_pressure_pa": 775.19,
  "atmospheric_density_kg_m3": 0.01889,
  "scale_height_km": 11.1,
  "aerodynamic_deceleration_margin": "Optimal",
  "temperature_kelvin_max": 267.0,
  "temperature_kelvin_min": 167.3,
  "temperature_kelvin_mean": 217.2,
  "temperature_celsius_max": -6.1,
  "temperature_celsius_min": -105.9,
  "temperature_celsius_mean": -56.0,
  "diurnal_swing_k": 99.7,
  "dust_optical_depth_tau": 0.35,
  "solar_attenuation_pct": -29.5,
  "annual_radiation_dose_msv": 241.5,
  "daily_cosmic_dose_usv": 661.2,
  "shielding_pct": 69.8,
  "geological_epoch": "Amazonian / Late Hesperian (1.5 - 3.5 Ga)"
}
```

---

## 7. Module 5: Rover Route Planning & Mission Persistence

### `POST /api/v1/mission/plan`
Computes a direct geodesic or terrain-aware path evaluated against rover engineering constraints.

**Request Body**:
```json
{
  "start_lat": 18.38,
  "start_lon": 77.58,
  "dest_lat": 18.27,
  "dest_lon": -24.63,
  "rover_type": "heavy",
  "routing_mode": "terrain_aware",
  "samples": 60
}
```

**Response `200 OK`**:
```json
{
  "start": {"latitude": 18.38, "longitude": 77.58},
  "destination": {"latitude": 18.27, "longitude": -24.63},
  "rover_profile": {
    "name": "Heavy Science Rover (Perseverance / Curiosity class)",
    "cruise_speed_kmh": 0.15,
    "daily_range_km": 0.20,
    "max_slope_deg": 20.0
  },
  "routing_mode": "terrain_aware",
  "total_distance_km": 5646.72,
  "estimated_driving_hours": 37644.8,
  "estimated_mission_sols": 28233.6,
  "driving_speed_kmh": 0.15,
  "daily_range_km": 0.20,
  "driving_hours_per_sol": 1.33,
  "rest_hours_per_sol": 23.33,
  "estimated_mission_earth_days": 29010.0,
  "estimated_mission_earth_years": 79.43,
  "route_safety_score": 70,
  "hazard_count": 0,
  "hazard_warnings": []
}
```

### `POST /api/v1/missions`
Persists a mission plan to PostgreSQL (or in-memory cache fallback).

### `GET /api/v1/missions`
Retrieves all saved mission plans.

---

## 8. Module 6: Survival Guide Decision Support

### `GET /api/v1/survival/evaluate`
Synthesizes a 6-pillar composite survival scorecard ($0 - 100$) and generates tailored aerospace architecture recommendations.

**Query Parameters**:
- `lat` (float, required), `lon` (float, required), `name` (string, optional).

**Response `200 OK`**:
```json
{
  "site_name": "Jezero Crater",
  "coordinates": {"latitude": 18.38, "longitude": 77.58},
  "overall_survival_score": 71,
  "suitability_classification": "CLASS II: VIABLE WITH OPERATIONAL MITIGATION",
  "pillars": {
    "edl_aerodynamic": 88,
    "terrain_touchdown": 50,
    "thermal_power": 92,
    "water_ice_isru": 35,
    "dust_storm_solar": 90,
    "astrobiology_science": 70
  },
  "recommendations": [
    "Standard Supersonic Parachute + Sky Crane Terminal Descent",
    "High-Efficiency Multi-Junction Solar Array with Secondary Battery Buffer",
    "Pressurized Heavy Exploration Rover",
    "High-Temperature Regolith Baking Soil Reactor"
  ]
}
```
