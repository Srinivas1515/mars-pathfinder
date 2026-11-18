# Mars Pathfinder API Documentation

Base URL: `http://localhost:8081`

## Endpoints

### 1. Health Status
- **Method**: `GET`
- **Route**: `/health`
- **Description**: Verifies service operational readiness.
- **Response `200 OK`**:
```json
{
  "status": "healthy",
  "service": "mars-pathfinder-api",
  "version": "1.0.0-foundation"
}
```

### 2. Database Health
- **Method**: `GET`
- **Route**: `/api/v1/health/database`
- **Description**: Verifies PostgreSQL & PostGIS connection and indexed tables.
- **Response `200 OK`**:
```json
{
  "status": "connected",
  "database": "mars_pathfinder"
}
```

### 3. Planetary Regions Gazetteer
- **Method**: `GET`
- **Route**: `/api/v1/regions`
- **Description**: Returns all cataloged Martian geographical exploration regions.
- **Response `200 OK`**:
```json
[
  {
    "id": "1",
    "name": "Jezero Crater",
    "description": "Ancient crater and delta exploration region",
    "longitude": 77.4,
    "latitude": 18.4
  },
  {
    "id": "2",
    "name": "Gale Crater",
    "description": "Curiosity rover exploration region",
    "longitude": 137.4,
    "latitude": -5.4
  },
  {
    "id": "3",
    "name": "Valles Marineris",
    "description": "Large Martian canyon system",
    "longitude": -70.0,
    "latitude": -10.0
  }
]
```

### 4. Map Layer Catalog
- **Method**: `GET`
- **Route**: `/api/v1/layers`
- **Description**: Returns metadata for scientific raster and vector layers available for 2D and 3D visualization.
- **Response `200 OK`**:
```json
[
  {
    "layer_key": "mola_color_hillshade",
    "name": "MOLA Global Color Hillshade",
    "description": "Global topographic elevation model shaded relief from MOLA instrument",
    "category": "terrain",
    "service_type": "WMTS",
    "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml",
    "external_layer_id": "Mars_MGS_MOLA_ClrShade_merge_global_463m",
    "coordinate_system": "EPSG:104905",
    "resolution_m": 463.0,
    "is_global": true
  }
]
```
