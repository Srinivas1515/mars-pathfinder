# ADR 0001: Dual Mapping Engines (CesiumJS for 3D & OpenLayers for 2D)

## Status
Accepted

## Context
A planetary exploration system for Mars requires two conflicting capabilities:
1. An intuitive, cinematic 3D planetary globe that lets users orbit Mars, view horizon curvature, inspect 3D terrain elevation, and rotate freely in spherical space.
2. A rigorous, high-precision 2D cartographic GIS workspace for comparing overlapping raster layers, measuring distances on equirectangular projections without perspective distortion, and inspecting high-resolution footprints.

## Decision
We decouple the user experience into two specialized mapping engines:
- **CesiumJS**: Default 3D planetary view. Uses the IAU Mars ellipsoid (`Cesium.Ellipsoid.MARS`) and Cesium Ion Mars 3D Tiles (Asset 3644333) with MOLA hillshade imagery.
- **OpenLayers**: 2D scientific analysis workspace. Uses the Mars Equirectangular CRS (`EPSG:104905`) with NASA Mars Trek tile streams, lat/lon graticule, and vector feature overlays.

Both mapping engines are unified by:
- A shared backend data catalog (`/api/v1/layers` and `/api/v1/regions`).
- Standardized coordinate conventions ($^\circ\text{E}, ^\circ\text{N}$).
- Mutually exclusive view rendering (they do not run concurrently in full-screen to minimize GPU/memory footprint).
