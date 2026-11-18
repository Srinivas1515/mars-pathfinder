# NASA Planetary Data Catalog & Integration Matrix

Mars Pathfinder integrates data from multiple planetary missions and instruments through a progressive hierarchical ingestion strategy.

## Primary Datasets

| Dataset | Mission | Instrument | Type | Resolution | Coverage | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MOLA Color Hillshade** | Mars Global Surveyor (MGS) | MOLA | Raster Topography | 463 m/px | Global (100%) | Active (P0) |
| **MOLA Elevation MEGDR** | Mars Global Surveyor (MGS) | MOLA | Topographic Gridded DEM | 128 px/deg (~463m) | Global (100%) | Pending (P0) |
| **MOLA Surface Roughness** | Mars Global Surveyor (MGS) | MOLA | Surface Roughness Raster | 463 m/px | Global (100%) | Planned (P0) |
| **THEMIS Daytime IR** | 2001 Mars Odyssey | THEMIS | Thermal / Mineralogy | 100 m/px | Global / Regional | Planned (P1) |
| **CTX Surface Context** | Mars Reconnaissance Orbiter (MRO) | CTX | Grayscale Morphology | 6 m/px | Regional footprints | Planned (P1) |
| **HiRISE Targeted Imagery** | Mars Reconnaissance Orbiter (MRO) | HiRISE | High-Res Visual / DTM | 0.25 - 0.5 m/px | High-priority sites | Planned (P1) |
| **CRISM Mineral Mappings** | Mars Reconnaissance Orbiter (MRO) | CRISM | Hyperspectral Mineralogy | 18 - 36 m/px | Observation bounds | Planned (P2) |
| **MEDA Weather Sensors** | Mars 2020 (Perseverance) | MEDA | In-situ Atmospheric | Local point | Jezero Crater | Planned (P2) |
| **RAD Radiation Detector**| Mars Science Lab (Curiosity) | RAD | Energetic Particle Flux | Local point | Gale Crater | Planned (P2) |

## Spatial Reference Standards
- **Cartographic CRS**: Mars Equirectangular (`EPSG:104905`)
- **Reference Ellipsoid**: IAU 2000 Mars sphere ($R = 3,396,190\text{ m}$)
- **Tile Hierarchy**: Equirectangular tile pyramid with 8 zoom levels (Level 0: $2\times 1$ tiles down to Level 7: $256\times 128$ tiles).
