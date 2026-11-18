# Mars Pathfinder — Coordinate Reference Systems & Planetary Geodesy Specification

**Standards Authority**: IAU/IAG Working Group on Cartographic Coordinates and Rotational Elements (WGCCRE)  
**Standard References**: Archinal et al. (2018), Seidelmann et al. (2002), Snyder (1987), MGS MOLA SIS  
**Status**: Authoritative Geodetic Specification — Fully Validated  

---

## 1. MOLA Dataset-Specific Projection & Georeferencing

A critical scientific distinction: **The MOLA MEGDR rasters do not use the Mars 2000 oblate ellipsoid.**
The authentic PDS label for `MEGT90N000CB` explicitly mandates:

```yaml
MAP_PROJECTION_TYPE: "SIMPLE CYLINDRICAL"
A_AXIS_RADIUS: 3396.0 <KM>
B_AXIS_RADIUS: 3396.0 <KM>
C_AXIS_RADIUS: 3396.0 <KM>
POSITIVE_LONGITUDE_DIRECTION: "EAST"
CENTER_LATITUDE: 0.0 <DEGREE>
CENTER_LONGITUDE: 180.0 <DEGREE>
LINE_PROJECTION_OFFSET: 360.5
SAMPLE_PROJECTION_OFFSET: 720.5
MAP_RESOLUTION: 4.0 <PIXEL/DEGREE>
COORDINATE_SYSTEM_NAME: "PLANETOCENTRIC"
```

### MOLA Georeferencing Mathematics

1. **Continuous 1-Based PDS Pixel Coordinates**:
   $$\text{Line}(\phi) = \text{LINE\_PROJECTION\_OFFSET} - (\phi - \text{CENTER\_LATITUDE}) \times \text{MAP\_RESOLUTION} = 360.5 - 4.0 \times \phi$$
   $$\text{Sample}(\lambda) = \text{SAMPLE\_PROJECTION\_OFFSET} + (\lambda_{360} - \text{CENTER\_LONGITUDE}) \times \text{MAP\_RESOLUTION} = 720.5 + 4.0 \times (\lambda_{360} - 180.0)$$

2. **0-Based Discrete Array Cell Indices $[row, col] \in [0..719, 0..1439]$**:
   $$row(\phi) = \min\left(719, \max\left(0, \lfloor (90.0 - \phi) \times 4.0 \rfloor\right)\right)$$
   $$col(\lambda_{360}) = \lfloor \lambda_{360} \times 4.0 \rfloor \pmod{1440}$$

3. **Inversion from 0-Based Pixel $[row, col]$ to Planetocentric Coordinates**:
   $$\phi_{\text{center}}(row) = 90.0 - \frac{row + 0.5}{4.0} = 89.875 - 0.25 \times row$$
   $$\lambda_{\text{center}}(col) = \frac{col + 0.5}{4.0} = 0.125 + 0.25 \times col$$
   * Latitudinal cell bounds: $[90.0 - 0.25(row+1), 90.0 - 0.25 row]$
   * Longitudinal cell bounds: $[0.25 col, 0.25(col+1)]$

### Critical Coordinate Verification Checkpoints

| Position | Latitude ($\phi$) | Longitude ($\lambda_{360}$) | PDS Line | PDS Sample | Array Row | Array Col |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **North Pole** | $+90.0^\circ$ | $0.0^\circ$ | $0.5$ (Top edge Line 1) | $0.5$ (Left edge Sample 1) | $0$ | $0$ |
| **Prime Meridian Equator** | $0.0^\circ$ | $0.0^\circ$ | $360.5$ (Line 360 boundary) | $0.5$ | $360$ | $0$ |
| **Center Meridian Equator** | $0.0^\circ$ | $180.0^\circ$ | $360.5$ | $720.5$ (Center sample) | $360$ | $720$ |
| **Eastern Boundary Equator** | $0.0^\circ$ | $360.0^\circ$ | $360.5$ | $1440.5$ (Wrap to 0.5) | $360$ | $0$ |
| **South Pole** | $-90.0^\circ$ | $0.0^\circ$ | $720.5$ (Bottom edge Line 720) | $0.5$ | $719$ | $0$ |

---

## 2. Polar Stereographic Product Family Georeferencing

Polar products (`MEGT_N_128_1.IMG`, `MEGT_S_128_1.IMG`) use Polar Stereographic projection referencing the polar spherical radius:
* **Datum Radius**: $R_{\text{polar}} = 3,376,200.0\text{ m}$ ($3376.2\text{ km}$, matching MOLA polar axis).
* **Center Latitude**: $+90.0^\circ$ (North Pole) or $-90.0^\circ$ (South Pole).
* **Grid Dimensions**: $10,240 \times 10,240$ pixels at 128 ppd.

---

## 3. Authoritative Mars 2000 Ellipsoid (`ESRI:104905`)

Preserved as a distinct Geographic 2D CRS for datasets (Viking MDIM 2.1, THEMIS, TES, and NASA Mars Trek WMTS):
* **Semi-Major Axis ($a$)**: $3,396,190.0\text{ m}$
* **Semi-Minor Axis ($b$)**: $3,376,200.0\text{ m}$
* **Flattening ($f$)**: $0.005886007556$, **Inverse Flattening ($1/f$)**: $169.8944472236118$
* **Proj4 Definition**:
  ```text
  +proj=longlat +a=3396190 +b=3376200 +no_defs
  ```

### Projected Metric CRS (`MARS:EQC` / `IAU2000:49910`)
* **Proj4 Definition**:
  ```text
  +proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +a=3396190 +b=3376200 +units=m +no_defs
  ```

---

## 4. WMTS Tile Alignment with MOLA Raster Coordinates

NASA Mars Trek WMTS (`default028mm`) uses top-left origin $(-180.0^\circ, +90.0^\circ)$ and tile matrix dimensions $[2 \times 2^Z, 2^Z]$.
Below is the mathematical alignment between NASA WMTS tiles and the MOLA 4 ppd raster ($720 \times 1440$):

| Landmark | Coordinates | MOLA Pixel $[row, col]$ | WMTS Zoom 0 Tile $[X, Y]$ | WMTS Zoom 1 Tile $[X, Y]$ | WMTS Zoom 2 Tile $[X, Y]$ |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Prime Meridian Equator** | $(0.0^\circ\text{N}, 0.0^\circ\text{E})$ | $[360, 0]$ | $[1, 0]$ | $[2, 1]$ | $[4, 2]$ |
| **Olympus Mons** | $(18.65^\circ\text{N}, -133.8^\circ\text{W} / 226.2^\circ\text{E})$ | $[285, 904]$ | $[0, 0]$ | $[1, 0]$ | $[2, 1]$ |
| **Hellas Planitia** | $(-42.4^\circ\text{S}, 70.5^\circ\text{E})$ | $[529, 282]$ | $[1, 0]$ | $[2, 1]$ | $[5, 2]$ |
| **Jezero Crater** | $(18.4^\circ\text{N}, 77.4^\circ\text{E})$ | $[286, 309]$ | $[1, 0]$ | $[2, 0]$ | $[5, 1]$ |
| **Gale Crater** | $(-5.4^\circ\text{S}, 137.4^\circ\text{E})$ | $[381, 549]$ | $[1, 0]$ | $[3, 1]$ | $[7, 2]$ |

Every WMTS tile coordinate mathematically aligns with the corresponding MOLA raster cell boundaries without residual sub-pixel drift.
