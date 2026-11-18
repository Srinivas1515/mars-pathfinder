# Scientific Data Quality, Physical Bounds & Provenance Framework
## Mars Pathfinder — Phase 1 Live Data Foundation

This document defines the data verification standards, physical validation limits, geodetic reference models, and cryptographic provenance rules governing all scientific observations and telemetry within the Mars Pathfinder platform.

---

## 1. Physical Validity & Sanity Boundaries

The Martian environment obeys well-established physical equations and empirical bounds documented across fifty years of robotic exploration (Viking, MGS, Mars Odyssey, MRO, MSL Curiosity, InSight, and Mars 2020 Perseverance).

The `DataValidator` engine (`processing/data_sources/validator.py`) enforces strict validation prior to ingestion:

| Variable | Physical Parameter | Minimum Valid Bound | Maximum Valid Bound | Reference / Anomaly Threshold |
| :--- | :--- | :--- | :--- | :--- |
| **Latitude** | Planetary Geocentric $\phi$ | $-90.0^\circ$ | $+90.0^\circ$ | Exact sphere bounds |
| **Longitude** | East-Positive $\lambda$ | $-180.0^\circ$ | $+180.0^\circ$ | Normalized from $0-360^\circ$ |
| **Surface Pressure** | $P_{surf}$ | $0.0\text{ Pa}$ | $2,500.0\text{ Pa}$ | Olympus Mons (~70 Pa) to Hellas (~1150 Pa) |
| **Air Temperature** | $T_{air}$ (1.5 m) | $120.0\text{ K}$ ($-153^\circ\text{C}$) | $320.0\text{ K}$ ($+47^\circ\text{C}$) | Polar winter night to equatorial noon |
| **Ground Skin Temp** | $T_{ground}$ | $120.0\text{ K}$ ($-153^\circ\text{C}$) | $320.0\text{ K}$ ($+47^\circ\text{C}$) | Radiative equilibrium skin temperature |
| **Horizontal Wind Speed** | $v_{wind}$ | $0.0\text{ m/s}$ | $60.0\text{ m/s}$ | Rare severe dust devil gusts $\le 45\text{ m/s}$ |
| **Wind Azimuth** | $\theta_{wind}$ | $0.0^\circ$ | $360.0^\circ$ | Geographic North $= 0^\circ$ |
| **Relative Humidity** | $RH$ | $0.0\%$ | $100.0\%$ | Saturation limit for water-ice |
| **Dust Optical Depth** | $\tau_{880nm}$ | $0.05$ | $6.0$ | Clear column (~0.3) to Global Dust Storm (>4.0) |
| **Solar Wind Velocity** | $v_{sw}$ | $200.0\text{ km/s}$ | $1,200.0\text{ km/s}$ | Fast CME shock waves reach ~1000 km/s |
| **Proton Density** | $n_p$ | $0.1\text{ cm}^{-3}$ | $100.0\text{ cm}^{-3}$ | Heliosphere at $1.524\text{ AU}$ |
| **Interplanetary Magnetic Field** | $B_z$ | $-50.0\text{ nT}$ | $+50.0\text{ nT}$ | Nominal background ~3 nT; ICME $\le 30\text{ nT}$ |

Any measurement exceeding these bounds is rejected or flagged as `BAD` or `QUESTIONABLE` and logged in `data_ingestion_logs`.

---

## 2. Observation Quality Flags

Every observation in the platform carries a standardized quality flag conforming to NASA PDS standards:

- `VALID`: Passed all physical boundary checks, instrument status flags nominal, and calibration verified.
- `QUESTIONABLE`: Observation deviates from expected climatological envelope by $> 3\sigma$, or sensor is reporting degraded mode (e.g. heated wind sensor wire partial obstruction).
- `BAD`: Unphysical reading (e.g., negative pressure, temperature $> 320\text{ K}$), parity check failed, or corrupted bitstream.
- `FILL_VALUE`: Known placeholder for missing or unmeasured data (e.g. $-9999.0$). Converted to `null` before UI presentation.
- `EXTRAPOLATED`: Synthesized via vertical hydrostatic integration or numerical interpolation beyond direct measurement range.
- `UNVERIFIED`: Raw or preliminary downlink prior to verification against calibration kernels.

---

## 3. Cartographic & Geodetic Standards

### 3.1 MOLA Megadr Spherical Reference (IAU 2000 Sphere)
- **CRS Code**: PDS:MOLA_SPHERE
- **Reference Body**: Spherical Mars
- **Radii**: $A = B = C = 3,396,000.0\text{ m}$ (Flattening $f = 0.0$)
- **Projection**: Equirectangular / Simple Cylindrical
- **Line/Sample Mapping**: Defined explicitly by authentic PDS labels (`MEGT90N000CB.LBL`):
  - Sample Offset: $S_0 = 11520.5$ (Center Longitude = $180.0^\circ$)
  - Line Offset: $L_0 = 5760.5$ (Equator at Line 5760.5)
  - Map Resolution: 128 pixels / degree
- **Vertical Datum**: Martian Areoid (MOLA GMM-3 gravitational potential model where $V = 12,654,107.5\text{ m}^2/\text{s}^2$, corresponding to the mean atmospheric pressure of $610.5\text{ Pa}$ at the triple point of water).

### 3.2 Mars 2000 Ellipsoidal Reference (ESRI:104905)
- **CRS Code**: ESRI:104905 / IAU:Mars_2000
- **Reference Body**: Triaxial / Oblate Ellipsoid
- **Radii**: Semi-major $A = 3,396,190.0\text{ m}$, Semi-minor $C = 3,376,200.0\text{ m}$ (Flattening $1/f \approx 169.81$)
- **Usage**: Kept strictly distinct from MOLA spherical rasters. Preserved for high-resolution vector layers and rover traverses that reference the Mars 2000 ellipsoid.

---

## 4. Telemetry Verification & Security Architecture

1. **Synthetic Simulation Segregation**:
   - Any synthetic telemetry generated for demonstration or driver training must have `is_synthetic: true` and `packet_type: "SIMULATED"`.
   - The UI immediately renders a distinct orange dashed border with a persistent `SYNTHETIC NOTICE` badge.
2. **Authentication Gate**:
   - Packets submitted with `packet_type: "AUTHENTICATED_EXTERNAL_TELEMETRY"` must contain a valid cryptographic signature in `authentication_signature`.
   - Packets failing signature verification are rejected with HTTP 400 Bad Request.
3. **SSRF Prevention**:
   - External data ingestion clients (`meda_client`, `mcs_client`, `ccmc_client`, `mars_trek_client`) only contact pre-approved domain whitelists (`*.nasa.gov`, `*.nmsu.edu`, `*.wustl.edu`, `*.arizona.edu`). Outbound HTTP calls to loopback, link-local, or private IP spaces are rejected by `BaseDataSourceClient`.

---

## 5. Provenance Metadata Tracking

Every observation record stores an immutable provenance trail:
- `provenance_id`: Unique PDS4 LIDVID or system trace identifier (e.g. `urn:nasa:pds:mars2020_meda:data_derived_env:meda_env_sol0920`).
- `source_key`: Authoritative repository identifier (`meda`, `mcs`, `mola`, `ccmc`, `spice`, `hirise`, `mars_trek`).
- `processing_level`: `RAW`, `CALIBRATED`, `DERIVED`, or `SYNTHESIZED`.
- `metadata.citation`: Mandatory academic publication citation.
- `metadata.pds_url`: Direct hyperlink to the backing PDS data node repository.
