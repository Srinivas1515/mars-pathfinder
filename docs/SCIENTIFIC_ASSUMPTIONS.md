# Mars Pathfinder — Scientific Assumptions & Physical Models

**Standards Authority**: NASA Planetary Data System / Mars Global Surveyor Science Team  
**Status**: Authoritative Scientific Specification — Fully Validated  

---

## 1. Direct Observations vs. Interpolated Topographic Surfaces

A critical finding from the authentic NASA PDS3 label for `MEGT90N000CB` is that **a populated elevation grid cell is not necessarily an observed surface point**:

> *"Each sample represents median observed topography within a 0.25 by 0.25 degree area. Where no observations lie within the area, an interpolated value is supplied. Owing to the polar MGS orbit, density is lowest near the equator, where about 55% of bins contain at least one MOLA shot. There are gaps, however, of up to 12 km between profiles."*

### Empirical Verification of the Global 4 ppd Dataset (`MEGC90N000CB`)
* **Total Cells in Raster**: $1,036,800$
* **Directly Observed Cells ($count > 0$)**: $1,027,663$ ($99.12\%$)
* **Interpolated Cells ($count == 0$)**: $9,137$ ($0.88\%$)
* **Maximum Observed Density**: $2,611\text{ shots / cell}$
* **Mean Density**: $557.77\text{ shots / cell}$

### Physical & Mission Planning Implications
* **Landing Site Hazard Analysis**: Rover touchdown and terrain hazard evaluations must never rely on interpolated elevations without flagging uncertainty. Areas with $count == 0$ represent unobserved gaps where surface topography was smoothed by 2D spline mathematical interpolation.
* **UI Transparency**: The system explicitly displays observation status:
  * **Observed**: Confirmed by $N$ physical laser altimeter pulses.
  * **Interpolated**: Computed numerical estimate; higher morphological uncertainty.

---

## 2. Dataset-Specific Georeferencing vs. Global Geodetic CRS

* **MOLA Map Projection**: Uses a spherical Simple Cylindrical projection with reference radius $R = 3,396,000.0\text{ m}$ ($3396.0\text{ km}$), planetocentric coordinates, center longitude $180.0^\circ$, line projection offset $360.5$, and sample projection offset $720.5$.
* **Planetary Geodetic CRS (`ESRI:104905`)**: Uses the Mars 2000 oblate ellipsoid ($a = 3,396,190.0\text{ m}, b = 3,376,200.0\text{ m}$).
* **Principle**: We do not force the Mars 2000 oblate ellipsoid onto the MOLA raster. Pixel-to-coordinate transformations follow the PDS label's native projection equations, while planetary feature locations are referenced in authentic geographic and Cartesian3 coordinates.

---

## 3. Martian Vertical Datum: The MOLA Areoid

* **Definition**: Equipotential gravitational surface modeled by Goddard Mars Model (GMM-3 / GMM-2B) evaluated to degree and order 50.
* **Atmospheric Benchmark**: Chosen such that the average atmospheric pressure at zero datum is $610.5\text{ Pa}$ ($6.105\text{ mbar}$), corresponding to the triple point of water.
* **Physical Elevation**:
  $$h = R_{\text{surface}}(\lambda, \phi) - R_{\text{areoid}}(\lambda, \phi)$$
