# Mars Pathfinder Architecture v1.0

## System Overview
Mars Pathfinder is an end-to-end planetary exploration and mission planning platform designed for full-Mars global visualization and deep scientific data inspection.

### Visualization Strategy
- **3D Planetary Globe (CesiumJS)**: Primary user experience for global orientation, rotating Mars, inspecting 3D terrain, coordinates, and high-altitude perspective.
- **2D Scientific Analysis Map (OpenLayers)**: Rigorous 2D GIS environment for multi-layer raster comparison, measuring distances on Mars ellipsoid, and inspecting MOLA/THEMIS/HiRISE layers without distortion artifacts.
- Both engines share a unified backend dataset catalog and synchronized coordinate systems.

### Hierarchical Data Strategy
- Planetary coverage is supported globally from Day 1.
- Hi-res scientific rasters (HiRISE, CTX) are loaded on-demand by geographic bounding box and zoom level rather than downloading full gigabyte archives.

### Stack
- **Frontend**: React 19 + TypeScript + Vite + Tailwind CSS v4 + Lucide Icons + TanStack Query + Zustand
- **Backend**: Go 1.26+ + Fiber v3 REST API
- **Spatial Database**: PostgreSQL 17 + PostGIS 3.5
- **Scientific Processing**: Python 3.12 + Rasterio + GDAL + PyProj
- **Storage & Infrastructure**: Cloudflare R2 / Docker Compose
