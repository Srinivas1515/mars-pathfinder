# Mars Pathfinder — Scientific Data Processing Pipeline

**Processing Engine**: Python 3.12 (NumPy, SciPy, PyProj, GeoPandas, Xarray)  
**API Integration**: Go Fiber v3 Subprocess IPC Bridge (`backend/internal/worker/worker.go`)  
**Status**: Authoritative Data Processing Specification — Fully Validated  

---

## 1. Topography & Observation Counts Dual-Raster Pipeline

Scientific rigor requires that data cells without direct altimetry returns are explicitly distinguished from observed surface returns.

```
       ┌────────────────────────┐      ┌────────────────────────┐
       │   MEGT90N000CB.IMG     │      │   MEGC90N000CB.IMG     │
       │ (16-bit Big-Endian >i2)│      │ (16-bit Big-Endian >i2)│
       │   Numerical Topography │      │   Observation Counts   │
       └───────────┬────────────┘      └───────────┬────────────┘
                   │                               │
                   └───────────────┬───────────────┘
                                   │
                                   ▼
                   ┌───────────────────────────────┐
                   │  MOLAMEGDRRasterInspector     │
                   │ (Dynamic PDS3 Metadata Reader)│
                   └───────────────┬───────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
     [ Elevation == -32768 ]  [ Count == 0 ]       [ Count > 0 ]
        status: "nodata"   status: "interpolated" status: "observed"
         is_obs: false        is_obs: false        is_obs: true
                              (Spline surface)    (N laser shots)
```

### Observation Support Classification
1. **Directly Observed (`status: "observed"`)**:
   * Condition: $\text{Count} > 0$ and $\text{Elevation} \neq -32768$.
   * Value represents the median elevation of $N$ direct laser altimeter ground returns in the $0.25^\circ \times 0.25^\circ$ cell.
   * Dataset metric (4 ppd): $1,027,663\text{ cells}$ ($99.12\%$).
2. **Interpolated (`status: "interpolated"`)**:
   * Condition: $\text{Count} == 0$ and $\text{Elevation} \neq -32768$.
   * Value was supplied by 2D surface spline interpolation because no MOLA laser shot struck that cell.
   * Dataset metric (4 ppd): $9,137\text{ cells}$ ($0.88\%$).
   * **Rule**: Never label interpolated values as direct observations in mission planning, science reports, or UI displays.
3. **Missing / NoData (`status: "missing"` / `"nodata"`)**:
   * Condition: $\text{Elevation} == -32768$. Excluded from terrain derivations.

---

## 2. Go Fiber API Elevation Query Contract

The authoritative Go Fiber backend exposes `/api/v1/elevation/point` querying the paired MOLA topography and counts engine:

### HTTP GET Request
```http
GET /api/v1/elevation/point?lat=18.4&lon=77.4 HTTP/1.1
Host: localhost:8081
```

### JSON Response (Directly Observed Cell — Jezero Crater)
```json
{
  "latitude": 18.4,
  "longitude": 77.4,
  "elevation_m": -2478.0,
  "observation_status": "observed",
  "observation_count": 787,
  "is_directly_observed": true,
  "vertical_datum": "Martian Areoid (MOLA GMM-3 / GMM-2B potential, 610.5 Pa)",
  "projection_datum_radius_m": 3396000.0,
  "product_id": "MEGT90N000CB.IMG",
  "counts_product_id": "megc90n000cb.IMG"
}
```

### JSON Response (Interpolated Cell — Polar Gap at 89.88°N, 1.38°E)
```json
{
  "latitude": 89.88,
  "longitude": 1.38,
  "elevation_m": -1977.0,
  "observation_status": "interpolated",
  "observation_count": 0,
  "is_directly_observed": false,
  "vertical_datum": "Martian Areoid (MOLA GMM-3 / GMM-2B potential, 610.5 Pa)",
  "projection_datum_radius_m": 3396000.0,
  "product_id": "MEGT90N000CB.IMG",
  "counts_product_id": "megc90n000cb.IMG"
}
```

---

## 3. Dedicated Polar Stereographic Processing Branch

Polar stereographic products (`MEGT_N_128_1.IMG`, `MEGT_S_128_1.IMG`) are routed to a separate processing branch that:
1. Reads 16-bit big-endian unsigned integers (`MSB_UNSIGNED_INTEGER`, `>u2`).
2. Applies polar calibration: $\text{Elevation} = (\text{DN} \times 0.25) - 8000.0\text{ meters}$.
3. Transforms polar planar coordinates $(x_p, y_p)$ using the polar spherical datum $R = 3,376,200.0\text{ m}$.
