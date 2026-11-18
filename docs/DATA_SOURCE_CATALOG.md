# NASA Planetary Data System (PDS) & Scientific Data Catalog
## Mars Pathfinder — Phase 1 Live Data Foundation

This document provides the authoritative, peer-reviewed data source catalog for Mars Pathfinder. Every data source in this catalog complies with NASA PDS4 / PDS3 standards, maintains strict geodetic integrity, and is integrated via the scientific processing engine.

---

## 1. Data Classification Standard

All data delivered across the platform is explicitly labeled using one of the following eight categories:

| Classification | Meaning & Operational Scope | Refresh / Latency |
| :--- | :--- | :--- |
| `LIVE` | Direct spacecraft downlink via NASA Deep Space Network (DSN) within 1 sol. | < 24 hours |
| `NEAR_REAL_TIME` | Downlinked within past 24–72 hours; preliminary calibration applied. | 24–72 hours |
| `RECENTLY_PUBLISHED` | Official NASA PDS mission release (e.g., M2020 Release 10, Sols 900–990). | Every 3–6 months |
| `HISTORICAL` | Fully validated, peer-reviewed PDS science archive product. | Permanent archive |
| `DERIVED` | High-level data product computed from verified archives (e.g. DTM, slope, thermal inertia). | On-demand / Cached |
| `MODELLED` | Physics-based numerical simulation (e.g., NASA Ames Mars GCM, hydrostatic equations). | Computed per epoch |
| `SIMULATED` | Synthetic telemetry or benchmark dataset for testing. Never presented as live. | Real-time simulation |
| `UNAVAILABLE` | Explicit null/unavailable state when no sensor or sounding coverage exists. | Non-existent |

---

## 2. Verified Data Source Catalog

### Source 1: MGS MOLA MEGDR & PEDR (Topography & Geodesy)
- **Source Key**: `mola`
- **Full Title**: Mars Global Surveyor Mars Orbiter Laser Altimeter Mission Experiment Gridded Data Record
- **Authoritative Provider**: NASA PDS Geosciences Node (Washington University in St. Louis)
- **PDS Node URL**: [https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/](https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/)
- **Product LIDVID**: `urn:nasa:pds:mgs_mola:megdr:megt90n000cb_v1`
- **Data Classification**: `HISTORICAL`
- **Processing Level**: `DERIVED` (NASA Level 3 / PDS4 Equivalent)
- **Coordinate Reference System (CRS)**:
  - Simple Cylindrical Projection
  - Reference Body: Spherical Mars with $R = 3,396.0\text{ km}$ ($A = B = C = 3,396,000\text{ m}$)
  - Longitude Convention: East-positive ($0^\circ$ to $360^\circ$ / $-180^\circ$ to $+180^\circ$)
  - Vertical Datum: Martian Areoid (MOLA GMM-3 / 610.5 Pa equipotential surface)
- **Spatial Coverage**: Global ($90^\circ\text{S}$ to $90^\circ\text{N}$, $180^\circ\text{W}$ to $180^\circ\text{E}$), 100% surface
- **Resolution**: 128 pixels/degree (~463 m/pixel at equator)
- **Variables Measured**: Topographic elevation relative to areoid ($m$), optical pulse width, surface reflectivity (1064 nm)
- **Citation**: Smith, D. E., et al. (2001). Mars Orbiter Laser Altimeter: Experiment summary and results. *Journal of Geophysical Research*, 106(E10), 23689–23722.

---

### Source 2: Mars 2020 Perseverance Rover MEDA (In-Situ Meteorology)
- **Source Key**: `meda`
- **Full Title**: Mars Environmental Dynamics Analyzer on the Mars 2020 Perseverance Rover
- **Authoritative Provider**: NASA PDS Atmospheres Node (New Mexico State University)
- **PDS Node URL**: [https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mars_2020/meda.html](https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mars_2020/meda.html)
- **Product LIDVID**: `urn:nasa:pds:mars2020_meda:data_derived_env:meda_env_sol0920`
- **Data Classification**: `RECENTLY_PUBLISHED` (Official PDS Releases)
- **Processing Level**: `CALIBRATED` (Level 3 / Calibrated Engineering Units)
- **Coordinate Reference System (CRS)**:
  - Local Surface Frame / Planetocentric Point
  - Location: Jezero Crater ($18.38^\circ\text{N}, 77.58^\circ\text{E}$, elevation $-2,530\text{ m}$)
- **Spatial Coverage**: In-situ point station ($\le 60\text{ km}$ valid local radius)
- **Update Cadence**: Quarterly NASA PDS data release sync
- **Instruments & Sensor Suite**:
  - **PS (Pressure Sensor)**: Atmospheric pressure ($Pa / mbar$) via vibrating silicon membrane.
  - **ATS (Air Temperature Sensor)**: 5 platinum RTD sensors across rover mast ($1.5\text{ m}$ height) and front ($^\circ C, K$).
  - **TIRS (Thermal Infrared Sensor)**: Ground surface temperature skin and upward/downward IR flux ($^\circ C, K$).
  - **WS (Wind Sensor)**: 2 wind booms measuring 2D/3D horizontal wind speed ($m/s$) and direction ($^\circ$ azimuth).
  - **HS (Humidity Sensor)**: Relative humidity (\%) and water vapor volume mixing ratio.
  - **RDS (Radiation & Dust Sensor)**: Dust optical depth ($\tau$ at 880 nm) and solar ultraviolet/visible irradiance ($W/m^2$).
  - **TIRS-UP / TIRS-DOWN**: Sky temperature and thermal balance.
- **Citation**: Rodriguez-Manfredi, J. A., et al. (2021). The Mars Environmental Dynamics Analyzer (MEDA) Instrument Suite on the Mars 2020 Mission. *Space Science Reviews*, 217(3), 48.

---

### Source 3: MRO Mars Climate Sounder (MCS) (Atmospheric Vertical Soundings)
- **Source Key**: `mcs`
- **Full Title**: Mars Reconnaissance Orbiter Mars Climate Sounder Atmospheric Limb Sounder
- **Authoritative Provider**: NASA PDS Atmospheres Node (New Mexico State University)
- **PDS Node URL**: [https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mro/mcs.html](https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mro/mcs.html)
- **Product LIDVID**: `urn:nasa:pds:mro_mcs:derived:profiles_l3_v1`
- **Data Classification**: `HISTORICAL` / `RECENTLY_PUBLISHED`
- **Processing Level**: `DERIVED` (Level 3 Vertical Inversion Profiles)
- **Coordinate Reference System (CRS)**: Planetocentric latitude/longitude + vertical altitude above MOLA datum
- **Spatial Coverage**: Global orbital limb tracks ($90^\circ\text{S}$ to $90^\circ\text{N}$)
- **Vertical Range**: 0 km to 70 km altitude above surface (5 km vertical resolution)
- **Variables Measured**:
  - Vertical atmospheric temperature profile $T(z)$ ($K$)
  - Vertical atmospheric pressure profile $P(z)$ ($Pa$)
  - Mineral dust opacity per kilometer ($km^{-1}$)
  - Water ice cloud opacity per kilometer ($km^{-1}$)
  - Atmospheric scale height $H = \frac{k_B T}{m g} \approx 11.1\text{ km}$
- **Citation**: McCleese, D. J., et al. (2007). Mars Climate Sounder: An investigation of thermal and water vapor structure, dust, and condensate clouds. *Journal of Geophysical Research*, 112(E5).

---

### Source 4: NASA CCMC / DONKI (Space Weather & SEP Radiation Hazard)
- **Source Key**: `ccmc`
- **Full Title**: Community Coordinated Modeling Center & Space Weather Database Of Notifications, Knowledge, Information
- **Authoritative Provider**: NASA Goddard Space Flight Center (GSFC)
- **PDS / Model Portal URL**: [https://ccmc.gsfc.nasa.gov](https://ccmc.gsfc.nasa.gov) / [https://kauai.ccmc.gsfc.nasa.gov/DONKI/](https://kauai.ccmc.gsfc.nasa.gov/DONKI/)
- **Product Identifier**: `nasa:ccmc:heliosphere:wsa_enlil_mars_1.52au`
- **Data Classification**: `MODELLED`
- **Processing Level**: `SYNTHESIZED`
- **Coordinate Reference System (CRS)**: Heliocentric Mars Orbit ($1.524\text{ AU}$)
- **Update Cadence**: Continuous 6-hour model run updates
- **Variables Measured**:
  - Solar wind speed $v_{sw}$ ($km/s$)
  - Solar wind proton density $n_p$ ($cm^{-3}$)
  - Interplanetary Magnetic Field component $B_z$ ($nT$)
  - Solar Energetic Particle (SEP) radiation hazard classification (`NOMINAL`, `MODERATE`, `HIGH`, `CRITICAL`)
  - Estimated surface cosmic ray dose rate ($mSv / sol$)
- **Citation**: Mays, M. L., et al. (2015). Ensemble Modeling of CME Arrival Time and Impact with WSA-ENLIL+Cone. *Solar Physics*, 290(6), 1775–1814.

---

### Source 5: NASA Mars Trek WMTS (Planetary Tile Basemaps)
- **Source Key**: `mars_trek`
- **Full Title**: NASA Solar System Treks Mars Web Map Tile Service (WMTS)
- **Authoritative Provider**: NASA Jet Propulsion Laboratory (JPL)
- **Service Endpoint URL**: [https://trek.nasa.gov/tiles/Mars/EQ/](https://trek.nasa.gov/tiles/Mars/EQ/)
- **Data Classification**: `HISTORICAL` / `DERIVED`
- **Processing Level**: `DERIVED` (Level 4 Web Tile Matrices)
- **Coordinate Reference System (CRS)**: EPSG:4326 Equirectangular / Simple Cylindrical
- **Spatial Coverage**: Global ($90^\circ\text{S}$ to $90^\circ\text{N}$, $180^\circ\text{W}$ to $180^\circ\text{E}$)
- **Registered Basemap Products**:
  1. `mola_color_hillshade`: MGS MOLA Global False Color Hillshade (Elevation $-8200\text{ m}$ to $+21200\text{ m}$)
  2. `viking_mdim21`: Viking Orbiter Mars Digital Image Mosaic 2.1 (Calibrated Albedo)
  3. `mgs_mola_shaded_relief`: MGS MOLA 128 PPD Shaded Relief Grayscale
  4. `themis_ir_day`: Mars Odyssey THEMIS Daytime Infrared Global Mosaic
  5. `themis_ir_night`: Mars Odyssey THEMIS Nighttime Thermal Inertia Global Mosaic
  6. `mars_dust_storm_hazard`: NASA Climatological Dust Storm Distribution Mosaic
- **Citation**: NASA Solar System Treks Project. (2024). Mars Trek Planetary Portal. Jet Propulsion Laboratory, California Institute of Technology.

---

### Source 6: MRO HiRISE (High-Resolution Stereo DTMs & Imagery)
- **Source Key**: `hirise`
- **Full Title**: Mars Reconnaissance Orbiter High Resolution Imaging Science Experiment
- **Authoritative Provider**: NASA PDS Planetary Data System & University of Arizona
- **PDS Node URL**: [https://hirise-pds.lpl.arizona.edu/PDS/](https://hirise-pds.lpl.arizona.edu/PDS/)
- **Product LIDVID**: `urn:nasa:pds:mro_hirise:dtm:jezero_delta_01`
- **Data Classification**: `HISTORICAL`
- **Processing Level**: `DERIVED` (Level 4 Stereo Digital Terrain Models)
- **Coordinate Reference System (CRS)**: Mars Equirectangular Planetocentric ($R = 3396.0\text{ km}$)
- **Spatial Coverage**: Targeted High-Priority Candidate Landing Sites:
  - Jezero Crater Delta ($18.38^\circ\text{N}, 77.58^\circ\text{E}$)
  - Oxia Planum Clay Deposits ($18.27^\circ\text{N}, -24.63^\circ\text{E}$)
  - Gale Crater sedimentary sequence ($ -5.4^\circ\text{N}, 137.4^\circ\text{E}$)
  - Mawrth Vallis phyllosilicate channels ($23.99^\circ\text{N}, -18.96^\circ\text{E}$)
- **Resolution**: $0.25\text{ m}$ to $1.0\text{ m}$ per pixel (meter-scale boulder and hazard detection)
- **Citation**: McEwen, A. S., et al. (2007). Mars Reconnaissance Orbiter's High Resolution Imaging Science Experiment (HiRISE). *Journal of Geophysical Research*, 112(E5).

---

### Source 7: NASA NAIF SPICE (Planetary Geometry & Ephemeris)
- **Source Key**: `spice`
- **Full Title**: NASA Navigation and Ancillary Information Facility SPICE Ephemeris Kernel System
- **Authoritative Provider**: NASA JPL NAIF Node
- **PDS Kernel Node URL**: [https://naif.jpl.nasa.gov/pub/naif/generic_kernels/](https://naif.jpl.nasa.gov/pub/naif/generic_kernels/)
- **Kernel IDs**: `de440.bsp` (Planetary Ephemeris), `pck00010.tpc` (Planetary Constants), `naif0012.tls` (Leapseconds)
- **Data Classification**: `DERIVED`
- **Processing Level**: `CALIBRATED`
- **Update Cadence**: High-precision ephemeris tables (J2000 barycentric coordinates)
- **Variables Computed**:
  - Solar Longitude $L_s$ ($0^\circ - 360^\circ$)
  - Martian Season (Northern Spring $0^\circ-90^\circ$, Summer $90^\circ-180^\circ$, Autumn $180^\circ-270^\circ$, Winter $270^\circ-360^\circ$)
  - Sun-Mars distance ($AU$, $km$)
  - Earth-Mars distance ($AU$, $km$)
  - One-Way Light-Time Telemetry Latency (minutes)
  - Solar Constant at Mars orbit: $S_{Mars} = \frac{S_0}{r_{AU}^2} \approx 588\text{ W/m}^2$
- **Citation**: Acton, C. H. (1996). Ancillary Data Services of NASA's Navigation and Ancillary Information Facility. *Planetary and Space Science*, 44(1), 65–70.

---

## 3. Telemetry Interface Specifications

For mission rovers, landers, and orbiters, Mars Pathfinder supports real-time downlinks under three strictly partitioned modes:

1. `SIMULATED`:
   - Generated dynamically for mission simulation, driver training, and algorithm benchmarking.
   - Distinctive visual styling (orange dashed border, simulation watermark).
   - Ingestion payload includes `is_synthetic: true`.
2. `TEST`:
   - System integration packets used for unit and automated regression tests.
3. `AUTHENTICATED_EXTERNAL_TELEMETRY`:
   - Production spacecraft downlinks.
   - Requires valid Ed25519 or HMAC cryptographic signature in the `authentication_signature` header.
   - Any packet asserting this classification without verification is rejected with HTTP 400.
