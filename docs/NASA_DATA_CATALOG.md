# Mars Pathfinder — Authoritative NASA Planetary Dataset Catalog

**Standard**: NASA Planetary Data System (PDS) / OGC WMTS (Open Geospatial Consortium)  
**Verification Authority**: NASA PDS Geosciences Node, USGS Astrogeology Science Center, NASA Solar System Treks  
**Official Reference**: [MOLA MEGDR Documentation (PDS Geosciences)](https://pds-geosciences.wustl.edu/missions/mgs/megdr.html)  
**Status**: Authoritative Scientific Catalog — Fully Validated  

---

## 1. MOLA MEGDR Planetary Topography, Altimetry & Counts Products

The Mars Orbiter Laser Altimeter (MOLA) Mission Experiment Gridded Data Records (MEGDR) are the primary geodetic and topographic products for Mars.

### The Four MOLA Data Product Series
* **`MEGT` — Topography**: Surface elevation in meters relative to the Areoid reference datum ($\text{Topography} = \text{Planetary Radius} - \text{Areoid Radius}$).
* **`MEGC` — Counts**: Number of valid laser altimeter observations (ground returns) within each spatial grid cell. **Essential for distinguishing genuine direct observations ($count > 0$) from 2D spline interpolated cells ($count == 0$).**
* **`MEGR` — Planetary Radius**: Raw radial distance from Mars center of mass to the ground return point in meters.
* **`MEGA` — Areoid**: Mars gravitational potential reference surface (datum) modeled by Goddard Mars Model (GMM-3 / GMM-2B) evaluated to degree and order 50.

---

## 2. Non-Polar Equirectangular Products (Global & Regional)

| Resolution Code | Pixels Per Degree (ppd) | Spatial Resolution (Equator) | Grid Dimensions (Rows × Cols) | Coverage | File Size | Product Naming Pattern |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **`C`** | 4 ppd | ~14.8 km / pixel | 720 × 1,440 | Global ($90^\circ\text{N}-90^\circ\text{S}, 0-360^\circ\text{E}$) | 2.07 MB | Topo: `MEGT90N000CB.IMG`<br>Counts: `MEGC90N000CB.IMG` |
| **`E`** | 16 ppd | ~3.7 km / pixel | 2,880 × 5,760 | Global ($90^\circ\text{N}-90^\circ\text{S}, 0-360^\circ\text{E}$) | 33.18 MB | Topo: `MEGT90N000EB.IMG`<br>Counts: `MEGC90N000EB.IMG` |
| **`F`** | 32 ppd | ~1.85 km / pixel | 5,760 × 11,520 | Global ($90^\circ\text{N}-90^\circ\text{S}, 0-360^\circ\text{E}$) | 132.71 MB | Topo: `MEGT90N000FB.IMG`<br>Counts: `MEGC90N000FB.IMG` |
| **`G`** | 64 ppd | ~926 m / pixel | 5,760 × 11,520 each | 4 Quadrant Tiles | 132.71 MB / tile (530.8 MB total) | Tiled (see below) |
| **`H`** | 128 ppd | ~463 m / pixel | 5,632 × 11,520 each | 16 Regional Tiles ($\pm 88^\circ$) | 129.76 MB / tile (2.07 GB total) | Tiled (see below) |

### 64 ppd Tiled Quadrants (`G` Resolution)
* `MEGT90N000GB.IMG` / `MEGC90N000GB.IMG` (NW Quadrant: $90^\circ\text{N}-0^\circ, 0^\circ-180^\circ\text{E}$)
* `MEGT90N180GB.IMG` / `MEGC90N180GB.IMG` (NE Quadrant: $90^\circ\text{N}-0^\circ, 180^\circ-360^\circ\text{E}$)
* `MEGT00N000GB.IMG` / `MEGC00N000GB.IMG` (SW Quadrant: $0^\circ-90^\circ\text{S}, 0^\circ-180^\circ\text{E}$)
* `MEGT00N180GB.IMG` / `MEGC00N180GB.IMG` (SE Quadrant: $0^\circ-90^\circ\text{S}, 180^\circ-360^\circ\text{E}$)

### 128 ppd Regional Tiles (`H` Resolution — 16 Tiles Covering $\pm 88^\circ$)
Each tile covers $44^\circ \text{ lat} \times 90^\circ \text{ lon}$ ($5,632 \times 11,520$ pixels):
* **Band 1 ($88^\circ\text{N}$ to $44^\circ\text{N}$)**: `MEGT88N000HB`, `MEGT88N090HB`, `MEGT88N180HB`, `MEGT88N270HB`
* **Band 2 ($44^\circ\text{N}$ to $00^\circ\text{N}$)**: `MEGT44N000HB`, `MEGT44N090HB`, `MEGT44N180HB`, `MEGT44N270HB`
* **Band 3 ($00^\circ\text{N}$ to $44^\circ\text{S}$)**: `MEGT00N000HB`, `MEGT00N090HB`, `MEGT00N180HB`, `MEGT00N270HB`
* **Band 4 ($44^\circ\text{S}$ to $88^\circ\text{S}$)**: `MEGT44S000HB`, `MEGT44S090HB`, `MEGT44S180HB`, `MEGT44S270HB`

---

## 3. Dedicated Polar Stereographic Product Family

> [!IMPORTANT]
> **Strict Architectural Separation**: Polar MOLA products are **NOT** equirectangular tiles. They constitute a distinct product family in **Polar Stereographic Projection** referencing a polar spherical radius of $R = 3,376,200.0\text{ m}$ ($3376.2\text{ km}$), centered at $\pm 90.0^\circ$ latitude.

### Official PDS Polar Product Naming Convention
$$\text{MEG}[T|C|R|A]\_[N|S]\_[128|256|512]\_[version].[\text{IMG}|\text{LBL}]$$

| Product Identifier | Hemisphere | Resolution (ppd) | Grid Dimensions | Projection | Radius Datum | Upstream Directory |
|:---|:---:|:---:|:---:|:---|:---:|:---|
| **`MEGT_N_128_1.IMG`** | North Pole | 128 ppd (~460 m/px) | 10,240 × 10,240 | Polar Stereographic ($+90^\circ\text{N}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |
| **`MEGT_S_128_1.IMG`** | South Pole | 128 ppd (~460 m/px) | 10,240 × 10,240 | Polar Stereographic ($-90^\circ\text{S}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |
| **`MEGT_N_256_1.IMG`** | North Pole | 256 ppd (~230 m/px) | 20,480 × 20,480 | Polar Stereographic ($+90^\circ\text{N}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |
| **`MEGT_S_256_1.IMG`** | South Pole | 256 ppd (~230 m/px) | 20,480 × 20,480 | Polar Stereographic ($-90^\circ\text{S}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |
| **`MEGT_N_512_1.IMG`** | North Pole | 512 ppd (~115 m/px) | 40,960 × 40,960 | Polar Stereographic ($+90^\circ\text{N}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |
| **`MEGT_S_512_1.IMG`** | South Pole | 512 ppd (~115 m/px) | 40,960 × 40,960 | Polar Stereographic ($-90^\circ\text{S}$) | $R = 3,376.2\text{ km}$ | `mgsl_300x/polar/` |

---

## 4. Authentic NASA Mars Trek WMTS Capabilities Specification

Derived directly from the authoritative XML endpoint:  
`https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml`

### WMTS TileMatrixSet: `default028mm`
* **Supported CRS**: `urn:ogc:def:crs:EPSG::104905` (Mars 2000 Geographic, degrees)
* **TopLeftCorner**: `-180.0 90.0`
* **Tile Dimensions**: $256 \times 256\text{ pixels}$
* **Assumed Display Pixel Size**: 0.28 mm (OGC WMTS standard)
* **RESTful URL Template**:
  ```text
  https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0//{Style}/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.jpg
  ```

### Complete Zoom Level Matrix (Levels 0 through 7)

| Level (`TileMatrix`) | Scale Denominator | Matrix Width (Cols) | Matrix Height (Rows) | Total Tiles | Longitude Span / Tile | Latitude Span / Tile |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **0** | $2.79227636 \times 10^8$ | 2 | 1 | 2 | $180.0^\circ$ | $180.0^\circ$ |
| **1** | $1.39613818 \times 10^8$ | 4 | 2 | 8 | $90.0^\circ$ | $90.0^\circ$ |
| **2** | $6.98069091 \times 10^7$ | 8 | 4 | 32 | $45.0^\circ$ | $45.0^\circ$ |
| **3** | $3.49034545 \times 10^7$ | 16 | 8 | 128 | $22.5^\circ$ | $22.5^\circ$ |
| **4** | $1.74517273 \times 10^7$ | 32 | 16 | 512 | $11.25^\circ$ | $11.25^\circ$ |
| **5** | $8.72586363 \times 10^6$ | 64 | 32 | 2,048 | $5.625^\circ$ | $5.625^\circ$ |
| **6** | $4.36293182 \times 10^6$ | 128 | 64 | 8,192 | $2.8125^\circ$ | $2.8125^\circ$ |
| **7** | $2.18146591 \times 10^6$ | 256 | 128 | 32,768 | $1.40625^\circ$ | $1.40625^\circ$ |

---

## 5. Global Verified Visualization Layers

1. **`mola_color_hillshade`**: MGS MOLA Global Color Hillshade (463 m/px, Levels 0–7)
2. **`mola_hrsc_blend_200m`**: MOLA + HRSC Blended Color Hillshade (200 m/px, Levels 0–8)
3. **`viking_mdim21_color`**: Viking MDIM 2.1 Controlled Color Mosaic (232 m/px, Levels 0–7)
4. **`themis_day_ir`**: 2001 Mars Odyssey THEMIS Daytime Thermal IR (100 m/px, Levels 0–8)
5. **`tes_albedo`**: MGS TES Global Surface Bolometric Albedo (7,410 m/px, Levels 0–5)
